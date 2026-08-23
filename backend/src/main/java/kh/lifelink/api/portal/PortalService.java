package kh.lifelink.api.portal;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.donation.Donation;
import kh.lifelink.api.donation.DonationRepository;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.donor.EligibilityCalculator;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.portal.dto.AcceptedDonorResponse;
import kh.lifelink.api.portal.dto.ConfirmDonationRequest;
import kh.lifelink.api.portal.dto.ConfirmDonationResponse;
import kh.lifelink.api.portal.dto.PortalRequestResponse;
import kh.lifelink.api.request.BloodRequest;
import kh.lifelink.api.request.BloodRequestRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * FR-PORTAL-001, trimmed by DEC-004 to one page: an open-requests table, and the one action that
 * makes {@code GET /donations/me} not permanently empty — confirming a donation.
 *
 * <p>{@code SecurityConfig} already refuses a non-HOSPITAL/ADMIN caller before this class runs.
 * What this class adds is the second half of RBAC that a role check alone cannot do: a HOSPITAL
 * account only ever sees or writes against its own hospital, never another's — scoped from
 * {@code users.hospital_id}, never from a request parameter.
 */
@Service
public class PortalService {

    private static final String OPEN = "OPEN";
    private static final String ACCEPTED = "ACCEPTED";
    private static final String ADMIN = "ADMIN";

    private final BloodRequestRepository requests;
    private final RequestMatchRepository matches;
    private final DonorProfileRepository donorProfiles;
    private final DonationRepository donations;
    private final UserRepository users;
    private final HospitalRepository hospitals;
    private final DistrictRepository districts;

    PortalService(
            BloodRequestRepository requests,
            RequestMatchRepository matches,
            DonorProfileRepository donorProfiles,
            DonationRepository donations,
            UserRepository users,
            HospitalRepository hospitals,
            DistrictRepository districts) {
        this.requests = requests;
        this.matches = matches;
        this.donorProfiles = donorProfiles;
        this.donations = donations;
        this.users = users;
        this.hospitals = hospitals;
        this.districts = districts;
    }

    /**
     * Only {@code OPEN} is supported — the DEC-004 trim is "a table of open requests," not a
     * general request browser, so a caller asking for anything else is refused rather than
     * silently given a filter nobody built.
     */
    @Transactional(readOnly = true)
    public List<PortalRequestResponse> listRequests(UUID callerId, String status) {
        if (!OPEN.equals(status)) {
            throw ApiException.unprocessable(
                    "UNSUPPORTED_STATUS", "Only status=OPEN is supported.");
        }

        User caller = requireUser(callerId);
        List<BloodRequest> rows =
                ADMIN.equals(caller.getRole())
                        ? requests.findByStatusOrderByCreatedAtDesc(status)
                        : requests.findByStatusAndHospitalIdOrderByCreatedAtDesc(
                                status, caller.getHospitalId());

        Map<UUID, Hospital> hospitalsById = hospitalsById(rows);
        Map<String, District> districtsByCode = districtsByCode();

        return rows.stream()
                .map(request -> toPortalResponse(request, hospitalsById, districtsByCode))
                .toList();
    }

    /**
     * One transaction, three writes — see {@code contract.md}'s "Confirm a donation": insert
     * {@code donations}, refresh the cached {@code last_donation_date}, close the request if this
     * was the last unit it needed.
     */
    @Transactional
    public ConfirmDonationResponse confirmDonation(UUID callerId, UUID requestId, ConfirmDonationRequest body) {
        LocalDate today = LocalDate.now();
        if (body.donatedOn().isAfter(today)) {
            throw ApiException.unprocessable(
                    "DONATION_DATE_IN_FUTURE", "The donation date cannot be in the future.");
        }

        User caller = requireUser(callerId);
        BloodRequest request =
                requests.findById(requestId)
                        .orElseThrow(
                                () ->
                                        ApiException.notFound(
                                                "REQUEST_NOT_FOUND", "No such request."));

        if (!ADMIN.equals(caller.getRole())
                && !request.getHospitalId().equals(caller.getHospitalId())) {
            // The *same* 404 as "no such request" — openapi.yaml documents this endpoint's 404 as
            // "Unknown request, or not visible to this caller". A distinguishable status here
            // (the previous 403 NOT_YOUR_HOSPITAL) would let a HOSPITAL account tell "doesn't
            // exist" apart from "exists, wrong hospital" by comparing error codes, which is
            // exactly the theatre this rule exists to avoid — same reasoning as GET
            // /requests/{id}'s donor-visibility check.
            throw ApiException.notFound("REQUEST_NOT_FOUND", "No such request.");
        }

        RequestMatch match =
                matches.findById(body.matchId())
                        .filter(m -> m.getBloodRequestId().equals(requestId))
                        .filter(m -> ACCEPTED.equals(m.getResponse()))
                        .orElseThrow(
                                // openapi.yaml's 422 for this endpoint is explicitly "matchId not
                                // ACCEPTED or not on this request" — a 404 here (the previous
                                // MATCH_NOT_FOUND) would contradict the documented contract, even
                                // though staff only ever learn a matchId through this request's
                                // own acceptedDonors list.
                                () ->
                                        ApiException.unprocessable(
                                                "MATCH_NOT_ACCEPTED",
                                                "No accepted match with that id on this request."));

        if (donations.existsByDonorProfileIdAndBloodRequestId(
                match.getDonorProfileId(), requestId)) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "DONATION_ALREADY_CONFIRMED",
                    "This donor's donation against this request is already confirmed.");
        }

        DonorProfile profile =
                donorProfiles
                        .findById(match.getDonorProfileId())
                        .orElseThrow(
                                () ->
                                        ApiException.notFound(
                                                "DONOR_PROFILE_NOT_FOUND",
                                                "No donor profile for that match."));

        Donation donation = new Donation();
        donation.setDonorProfileId(profile.getId());
        donation.setHospitalId(request.getHospitalId());
        donation.setBloodRequestId(requestId);
        donation.setDonatedOn(body.donatedOn());
        donation.setConfirmedByUserId(callerId);
        try {
            donation = donations.save(donation);
        } catch (org.springframework.dao.DataIntegrityViolationException ex) {
            // The existsBy check above is a race, not a guarantee — two confirm-donation calls
            // for the same match arriving close together can both pass it before either commits.
            // V9__donations_unique.sql is the actual guarantee; this turns its violation into the
            // same 409 the check above produces, rather than the generic CONSTRAINT_VIOLATED 422
            // from GlobalExceptionHandler, whose "a referenced value does not exist" message would
            // be actively wrong here — the value exists twice, not zero times.
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "DONATION_ALREADY_CONFIRMED",
                    "This donor's donation against this request is already confirmed.");
        }

        // The cache wins only when this donation is the newest one on record — confirming an
        // older, backdated donation must not push a donor's cooldown backwards past a donation
        // already known to be more recent.
        if (profile.getLastDonationDate() == null
                || body.donatedOn().isAfter(profile.getLastDonationDate())) {
            profile.setLastDonationDate(body.donatedOn());
            donorProfiles.save(profile);
        }

        int confirmedCount = donations.countByBloodRequestId(requestId);
        if (confirmedCount >= request.getUnitsNeeded()) {
            request.setStatus("FULFILLED");
            requests.save(request);
        }

        return new ConfirmDonationResponse(
                donation.getId(),
                profile.getFullName(),
                donation.getDonatedOn(),
                request.getStatus(),
                donation.getDonatedOn().plusDays(EligibilityCalculator.COOLDOWN_DAYS));
    }

    private User requireUser(UUID userId) {
        return users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "No such user."));
    }

    private PortalRequestResponse toPortalResponse(
            BloodRequest request,
            Map<UUID, Hospital> hospitalsById,
            Map<String, District> districtsByCode) {
        List<RequestMatch> accepted = matches.findByBloodRequestIdAndResponse(request.getId(), ACCEPTED);

        // `acceptedCount` is every ACCEPTED match, same meaning as the mobile contract's
        // acceptedCount — computed on read, one definition for both clients. `acceptedDonors`
        // is narrower on purpose: it is the actionable list, so a donor whose donation this
        // hospital already confirmed drops off it rather than sitting there with a "confirm"
        // button that would only 409.
        List<AcceptedDonorResponse> acceptedDonors =
                accepted.stream()
                        .filter(
                                match ->
                                        !donations.existsByDonorProfileIdAndBloodRequestId(
                                                match.getDonorProfileId(), request.getId()))
                        .map(match -> toAcceptedDonor(match, districtsByCode))
                        .filter(java.util.Objects::nonNull)
                        .sorted(Comparator.comparing(AcceptedDonorResponse::respondedAt))
                        .toList();

        return new PortalRequestResponse(
                request.getId(),
                request.getPatientBloodType(),
                request.getUnitsNeeded(),
                request.getUrgency(),
                request.getStatus(),
                hospitalResponse(hospitalsById.get(request.getHospitalId()), districtsByCode),
                matches.countByBloodRequestId(request.getId()),
                accepted.size(),
                request.getCreatedAt(),
                acceptedDonors);
    }

    private AcceptedDonorResponse toAcceptedDonor(
            RequestMatch match, Map<String, District> districtsByCode) {
        return donorProfiles
                .findById(match.getDonorProfileId())
                .map(
                        profile -> {
                            District district = districtsByCode.get(profile.getDistrictCode());
                            return new AcceptedDonorResponse(
                                    match.getId(),
                                    profile.getFullName(),
                                    profile.getBloodType(),
                                    district == null ? null : district.getNameEn(),
                                    match.getRespondedAt());
                        })
                .orElse(null);
    }

    private HospitalResponse hospitalResponse(Hospital hospital, Map<String, District> districtsByCode) {
        if (hospital == null) {
            return null;
        }
        District district =
                hospital.getDistrictCode() == null ? null : districtsByCode.get(hospital.getDistrictCode());
        return new HospitalResponse(
                hospital.getId(),
                hospital.getName(),
                district == null ? null : new DistrictName(district.getNameKm(), district.getNameEn()));
    }

    private Map<UUID, Hospital> hospitalsById(List<BloodRequest> rows) {
        List<UUID> ids = rows.stream().map(BloodRequest::getHospitalId).distinct().toList();
        return hospitals.findAllById(ids).stream()
                .collect(Collectors.toMap(Hospital::getId, Function.identity()));
    }

    private Map<String, District> districtsByCode() {
        return districts.findAll().stream()
                .collect(Collectors.toMap(District::getCode, Function.identity()));
    }
}
