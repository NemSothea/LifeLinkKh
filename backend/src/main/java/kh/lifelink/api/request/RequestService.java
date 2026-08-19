package kh.lifelink.api.request;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.notify.RequestAlertNotifier;
import kh.lifelink.api.request.dto.BloodRequestDetailResponse;
import kh.lifelink.api.request.dto.BloodRequestResponse;
import kh.lifelink.api.request.dto.RequestCreateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** FR-REQUEST-001, and the trigger for FR-MATCH-001 and FR-NOTIFY-001. */
@Service
public class RequestService {

    private static final String OPEN = "OPEN";

    private final BloodRequestRepository requests;
    private final DonorProfileRepository donorProfiles;
    private final RequestMatchRepository matches;
    private final RequestCreation creation;
    private final RequestAlertNotifier notifier;
    private final RequestRateLimiter rateLimiter;
    private final RequestViews views;

    RequestService(
            BloodRequestRepository requests,
            DonorProfileRepository donorProfiles,
            RequestMatchRepository matches,
            RequestCreation creation,
            RequestAlertNotifier notifier,
            RequestRateLimiter rateLimiter,
            RequestViews views) {
        this.requests = requests;
        this.donorProfiles = donorProfiles;
        this.matches = matches;
        this.creation = creation;
        this.notifier = notifier;
        this.rateLimiter = rateLimiter;
        this.views = views;
    }

    /**
     * Create, match and alert — in that order, in one call.
     *
     * <p>The contract is explicit that matching and push run inside this request rather than on a
     * queue: FR-04 requires notification on creation and the NFR is under 10 seconds end to end. A
     * job runner would be a second failure surface for a path that has to work in ten seconds
     * anyway.
     *
     * <p><strong>Not transactional, on purpose.</strong> The database work is atomic inside {@link
     * RequestCreation}; the FCM send happens after it commits and cannot roll it back. An outage
     * leaves a real request with real matches and {@code notified_at} NULL. The alternative — a 500
     * on a failed send — leaves the requester with nothing, so they retry, and now there are two
     * requests for one patient.
     */
    public BloodRequestResponse create(UUID userId, RequestCreateRequest body) {
        if (!rateLimiter.tryAcquire(userId)) {
            throw ApiException.rateLimited(
                    "REQUEST_RATE_LIMITED", "Too many requests. Try again shortly.");
        }

        RequestCreation.Created created = creation.createAndMatch(userId, body);

        Set<UUID> notified =
                notifier.alert(
                        created.request().getId(),
                        created.request().getPatientBloodType(),
                        created.hospitalName(),
                        created.matchedDonorProfileIds());
        creation.stampNotified(created.request().getId(), notified);

        return views.summary(created.request());
    }

    @Transactional(readOnly = true)
    public List<BloodRequestResponse> listMine(UUID userId) {
        return requests.findByCreatedByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(views::summary)
                .toList();
    }

    /**
     * Visible to the creator, and to a donor matched to it. Everyone else gets 404, not 403 — a 403
     * confirms the request exists, which turns this endpoint into an oracle for enumerating blood
     * requests.
     */
    @Transactional(readOnly = true)
    public BloodRequestDetailResponse read(UUID userId, UUID requestId) {
        BloodRequest request = requests.findById(requestId).orElseThrow(RequestService::notVisible);

        if (request.getCreatedByUserId().equals(userId)) {
            // The creator already knows their own number, so there is nothing to reveal here.
            return views.detail(request, null, null);
        }

        RequestMatch match =
                donorProfiles
                        .findByUserId(userId)
                        .map(DonorProfile::getId)
                        .flatMap(
                                profileId ->
                                        matches.findByBloodRequestIdAndDonorProfileId(
                                                requestId, profileId))
                        .orElseThrow(RequestService::notVisible);

        return views.detail(request, match.getResponse(), match.getDistanceKm());
    }

    /**
     * Closing a request does not happen automatically anywhere in this build. Acceptances do not
     * close it — a request needing three units and holding one acceptance is still open — and there
     * is no expiry (FR-REQUEST-005 deferred).
     */
    @Transactional
    public BloodRequestResponse cancel(UUID userId, UUID requestId) {
        BloodRequest request = requests.findById(requestId).orElseThrow(RequestService::notVisible);

        if (!request.getCreatedByUserId().equals(userId)) {
            // 403 rather than the 404 used by read(): reaching this endpoint means the caller was
            // given the id, so hiding its existence would be theatre.
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "NOT_REQUEST_CREATOR",
                    "Only the creator can close this request.");
        }
        if (!OPEN.equals(request.getStatus())) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "REQUEST_ALREADY_CLOSED",
                    "This request is already closed.");
        }

        request.setStatus("CANCELLED");
        return views.summary(requests.save(request));
    }

    private static ApiException notVisible() {
        return ApiException.notFound("REQUEST_NOT_FOUND", "No such request.");
    }
}
