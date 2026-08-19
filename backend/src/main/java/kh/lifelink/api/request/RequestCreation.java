package kh.lifelink.api.request;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.match.MatchingService;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.request.dto.RequestCreateRequest;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * The two transactional halves of request creation, in their own bean.
 *
 * <p>Its own bean specifically because {@code @Transactional} is applied by a proxy: if {@link
 * RequestService#create} called these as its own methods, the calls would not go through the proxy
 * and neither annotation would do anything. That failure is silent — the code runs, the rows
 * appear, and nothing is atomic. Splitting the collaborator out is the fix that cannot be undone by
 * accident.
 */
@Component
class RequestCreation {

    private static final Set<String> BLOOD_TYPES =
            Set.of("O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+");
    private static final Set<String> URGENCIES = Set.of("CRITICAL", "URGENT", "ROUTINE");

    /** What creation produced, for the caller to alert on. */
    record Created(BloodRequest request, String hospitalName, List<UUID> matchedDonorProfileIds) {}

    private final BloodRequestRepository requests;
    private final HospitalRepository hospitals;
    private final RequestMatchRepository matches;
    private final MatchingService matching;

    RequestCreation(
            BloodRequestRepository requests,
            HospitalRepository hospitals,
            RequestMatchRepository matches,
            MatchingService matching) {
        this.requests = requests;
        this.hospitals = hospitals;
        this.matches = matches;
        this.matching = matching;
    }

    /**
     * Validate, insert the request, match, and write one row per matched donor — all or nothing.
     *
     * <p>The push is deliberately not here. It is I/O to a third party, and holding a database
     * transaction open across it would make an FCM slowdown into database lock contention.
     */
    @Transactional
    Created createAndMatch(UUID userId, RequestCreateRequest body) {
        if (!BLOOD_TYPES.contains(body.patientBloodType())) {
            throw ApiException.unprocessable("UNKNOWN_BLOOD_TYPE", "That blood type is not valid.");
        }
        if (!URGENCIES.contains(body.urgency())) {
            throw ApiException.unprocessable("UNKNOWN_URGENCY", "That urgency is not valid.");
        }

        Hospital hospital =
                hospitals
                        .findById(body.hospitalId())
                        // 422 rather than 404: a 404 would turn this endpoint into an oracle for
                        // which UUIDs are real hospitals.
                        .orElseThrow(
                                () ->
                                        ApiException.unprocessable(
                                                "UNKNOWN_HOSPITAL", "That hospital is not valid."));

        BloodRequest request = new BloodRequest();
        request.setCreatedByUserId(userId);
        request.setHospitalId(hospital.getId());
        request.setPatientBloodType(body.patientBloodType());
        request.setUnitsNeeded(body.unitsNeeded().shortValue());
        request.setUrgency(body.urgency());
        request.setStatus("OPEN");
        request.setContactName(body.contactName());
        request.setContactPhone(body.contactPhone());
        BloodRequest saved = requests.save(request);

        List<MatchingService.Candidate> candidates =
                matching.findFor(saved.getPatientBloodType(), hospital);

        List<UUID> matchedIds = new ArrayList<>(candidates.size());
        for (MatchingService.Candidate candidate : candidates) {
            RequestMatch match = new RequestMatch();
            match.setBloodRequestId(saved.getId());
            match.setDonorProfileId(candidate.donorProfileId());
            match.setDistanceKm(candidate.distanceKm());
            matches.save(match);
            matchedIds.add(candidate.donorProfileId());
        }

        return new Created(saved, hospital.getName(), matchedIds);
    }

    /**
     * Stamps only the donors FCM accepted. A donor with no token, or one whose send failed, keeps
     * {@code notified_at} NULL — which is exactly why {@code alertedCount} counts rows written and
     * the PRD's delivery metric counts stamps.
     */
    @Transactional
    void stampNotified(UUID requestId, Set<UUID> notifiedDonorProfileIds) {
        if (notifiedDonorProfileIds.isEmpty()) {
            return;
        }
        OffsetDateTime now = OffsetDateTime.now();
        for (RequestMatch match : matches.findByBloodRequestId(requestId)) {
            if (notifiedDonorProfileIds.contains(match.getDonorProfileId())) {
                match.setNotifiedAt(now);
                matches.save(match);
            }
        }
    }
}
