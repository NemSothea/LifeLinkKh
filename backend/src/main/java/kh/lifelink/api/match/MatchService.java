package kh.lifelink.api.match;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.match.dto.MatchResponse;
import kh.lifelink.api.match.dto.RespondRequest;
import kh.lifelink.api.match.dto.RespondResponse;
import kh.lifelink.api.request.BloodRequest;
import kh.lifelink.api.request.BloodRequestRepository;
import kh.lifelink.api.request.RequestViews;
import kh.lifelink.api.request.dto.RequesterContact;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** FR-REQUEST-002 — the donor's side of the loop, and the trigger for FR-NOTIFY-003. */
@Service
public class MatchService {

    /**
     * WITHDRAWN is absent deliberately. The column accepts it, {@code V1__init.sql} says so, and no
     * FR defines what withdrawing means — FR-REQUEST-004 is deferred. An enum value with no rule
     * behind it is a state nothing knows how to leave.
     */
    private static final Set<String> RESPONSES = Set.of("ACCEPTED", "DECLINED");

    private final RequestMatchRepository matches;
    private final DonorProfileRepository donorProfiles;
    private final BloodRequestRepository requests;
    private final RequestViews views;
    private final ApplicationEventPublisher events;

    MatchService(
            RequestMatchRepository matches,
            DonorProfileRepository donorProfiles,
            BloodRequestRepository requests,
            RequestViews views,
            ApplicationEventPublisher events) {
        this.matches = matches;
        this.donorProfiles = donorProfiles;
        this.requests = requests;
        this.views = views;
        this.events = events;
    }

    @Transactional(readOnly = true)
    public List<MatchResponse> listMine(UUID userId) {
        DonorProfile profile = requireProfile(userId);

        return matches.findByDonorProfileId(profile.getId()).stream()
                .map(
                        match ->
                                requests.findById(match.getBloodRequestId())
                                        .map(
                                                request ->
                                                        new MatchResponse(
                                                                match.getId(),
                                                                views.detail(
                                                                        request,
                                                                        match.getResponse(),
                                                                        match.getDistanceKm()),
                                                                profile.getBloodType(),
                                                                match.getResponse(),
                                                                match.getNotifiedAt()))
                                        .orElse(null))
                .filter(java.util.Objects::nonNull)
                .toList();
    }

    /**
     * The one place a phone number is revealed, so the three guards below are the whole feature.
     *
     * <p>403 rather than 404 for someone else's match: the caller was given the id by {@code
     * /matches/me} or by a push payload, so pretending it does not exist would be theatre. That is
     * the opposite of {@code GET /requests/{id}}, and the difference is deliberate.
     */
    @Transactional
    public RespondResponse respond(UUID userId, UUID matchId, RespondRequest body) {
        return respond(userId, matchId, body, null);
    }

    /**
     * The same call, carrying the key a queued offline answer was written with.
     *
     * <p>A replay of a write the server already applied returns that stored answer instead of 409
     * ALREADY_RESPONDED. The donor did not answer twice — their phone lost the reply on the way
     * back and the sync engine sent the same write again. Answering 409 there would clear the
     * pending badge with an error on a device whose acceptance actually landed.
     */
    @Transactional
    public RespondResponse respond(
            UUID userId, UUID matchId, RespondRequest body, String idempotencyKey) {
        String response = body.response();
        if (!RESPONSES.contains(response)) {
            throw ApiException.unprocessable(
                    "UNKNOWN_RESPONSE", "A response must be ACCEPTED or DECLINED.");
        }

        DonorProfile profile = requireProfile(userId);
        RequestMatch match =
                matches.findById(matchId)
                        .orElseThrow(
                                () -> ApiException.notFound("MATCH_NOT_FOUND", "No such match."));

        if (!match.getDonorProfileId().equals(profile.getId())) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN, "NOT_YOUR_MATCH", "That is not your match.");
        }
        if (match.getResponse() != null) {
            // Same key on the same match: this is the reply already applied, arriving again because
            // the client never saw the answer. Hand back what was stored.
            if (idempotencyKey != null && idempotencyKey.equals(match.getIdempotencyKey())) {
                return new RespondResponse(
                        match.getId(),
                        match.getResponse(),
                        match.getRespondedAt(),
                        contactFor(match));
            }
            // One response, never overwritten. Changing your mind is FR-REQUEST-004, deferred.
            throw new ApiException(
                    HttpStatus.CONFLICT, "ALREADY_RESPONDED", "You have already answered this.");
        }

        match.setResponse(response);
        match.setRespondedAt(OffsetDateTime.now());
        match.setIdempotencyKey(idempotencyKey);
        matches.save(match);

        if ("ACCEPTED".equals(response)) {
            // FR-NOTIFY-003. Delivered only once this transaction commits — see
            // AcceptanceNotifier. Below the replay branch above on purpose: a replayed
            // acceptance already told the family once.
            events.publishEvent(new DonorAccepted(match.getId(), match.getBloodRequestId()));
        }

        return new RespondResponse(
                match.getId(), response, match.getRespondedAt(), contactFor(match));
    }

    /**
     * The requester's contact details, revealed only to a donor who accepted. A replay has to
     * return the same thing the original call did, so this is one method rather than two.
     */
    private RequesterContact contactFor(RequestMatch match) {
        if (!"ACCEPTED".equals(match.getResponse())) {
            return null;
        }
        BloodRequest request =
                requests.findById(match.getBloodRequestId())
                        .orElseThrow(
                                () ->
                                        ApiException.notFound(
                                                "REQUEST_NOT_FOUND", "No such request."));
        return RequesterContact.of(request.getContactName(), request.getContactPhone());
    }

    private DonorProfile requireProfile(UUID userId) {
        return donorProfiles
                .findByUserId(userId)
                // A REQUESTER has no donor profile and therefore no matches. Not a fault.
                .orElseThrow(
                        () ->
                                ApiException.notFound(
                                        "DONOR_PROFILE_NOT_FOUND", "No donor profile yet."));
    }
}
