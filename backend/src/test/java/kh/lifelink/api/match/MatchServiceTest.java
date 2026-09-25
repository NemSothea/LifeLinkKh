package kh.lifelink.api.match;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.match.dto.RespondRequest;
import kh.lifelink.api.match.dto.RespondResponse;
import kh.lifelink.api.request.BloodRequest;
import kh.lifelink.api.request.BloodRequestRepository;
import kh.lifelink.api.request.RequestViews;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;

/**
 * FR-REQUEST-002. Every test here is about one rule: a phone number is revealed on ACCEPTED and on
 * nothing else (TM-AUTH-001 I1).
 */
class MatchServiceTest {

    private static final UUID CALLER = UUID.randomUUID();
    private static final UUID MY_PROFILE = UUID.randomUUID();
    private static final UUID SOMEONE_ELSES_PROFILE = UUID.randomUUID();
    private static final UUID MATCH_ID = UUID.randomUUID();
    private static final UUID REQUEST_ID = UUID.randomUUID();

    private RequestMatchRepository matches;
    private DonorProfileRepository donorProfiles;
    private BloodRequestRepository requests;
    private ApplicationEventPublisher events;
    private MatchService service;

    @BeforeEach
    void setUp() {
        matches = mock(RequestMatchRepository.class);
        donorProfiles = mock(DonorProfileRepository.class);
        requests = mock(BloodRequestRepository.class);
        events = mock(ApplicationEventPublisher.class);
        service =
                new MatchService(
                        matches, donorProfiles, requests, mock(RequestViews.class), events);

        DonorProfile profile = mock(DonorProfile.class);
        when(profile.getId()).thenReturn(MY_PROFILE);
        when(profile.getBloodType()).thenReturn("O-");
        when(donorProfiles.findByUserId(CALLER)).thenReturn(Optional.of(profile));

        BloodRequest request = new BloodRequest();
        request.setContactName("Sokha");
        request.setContactPhone("012345678");
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(request));
    }

    @Test
    void acceptingRevealsTheRequesterContact() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        RespondResponse response =
                service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED"));

        assertThat(response.requesterContact()).isNotNull();
        assertThat(response.requesterContact().displayName()).isEqualTo("Sokha");
        assertThat(response.requesterContact().phone()).isEqualTo("012345678");
    }

    /**
     * Null, not an empty object. A client bug should read as a crash rather than as a contact card
     * with blank fields that someone tries to dial.
     */
    @Test
    void decliningRevealsNothing() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        RespondResponse response =
                service.respond(CALLER, MATCH_ID, new RespondRequest("DECLINED"));

        assertThat(response.requesterContact()).isNull();
    }

    /** Phone numbers are unverified in this build (ADR 0002) and the client must say so. */
    @Test
    void aRevealedPhoneIsAlwaysMarkedUnverified() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        RespondResponse response =
                service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED"));

        assertThat(response.requesterContact().phoneVerified()).isFalse();
    }

    @Test
    void answeringSomeoneElsesMatchIsForbidden() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(SOMEONE_ELSES_PROFILE)));

        assertThatThrownBy(() -> service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED")))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.FORBIDDEN);

        verify(matches, never()).save(any());
    }

    /** One response, never overwritten. Changing your mind is FR-REQUEST-004, deferred. */
    @Test
    void answeringTwiceConflicts() {
        RequestMatch answered = unanswered(MY_PROFILE);
        answered.setResponse("DECLINED");
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(answered));

        assertThatThrownBy(() -> service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED")))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    /**
     * The offline-first replay. The donor's phone queued an acceptance, sent it, and never saw the
     * reply — so the sync engine sent the same write again, carrying the key it was queued with.
     * Answering 409 there would clear the pending badge with an error on a device whose acceptance
     * actually landed, and a hospital counting on that donor would never learn they accepted.
     */
    @Test
    void replayingAQueuedAnswerReturnsTheStoredOne() {
        RequestMatch answered = unanswered(MY_PROFILE);
        answered.setResponse("ACCEPTED");
        answered.setRespondedAt(java.time.OffsetDateTime.now());
        answered.setIdempotencyKey("a1b2c3");
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(answered));

        RespondResponse replay =
                service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED"), "a1b2c3");

        assertThat(replay.response()).isEqualTo("ACCEPTED");
        assertThat(replay.requesterContact()).isNotNull();
        verify(matches, never()).save(any());
    }

    /** A replay is recognised by its key, not by arriving second. */
    @Test
    void aDifferentKeyOnAnAnsweredMatchStillConflicts() {
        RequestMatch answered = unanswered(MY_PROFILE);
        answered.setResponse("ACCEPTED");
        answered.setIdempotencyKey("a1b2c3");
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(answered));

        assertThatThrownBy(
                        () ->
                                service.respond(
                                        CALLER, MATCH_ID, new RespondRequest("DECLINED"), "zzz999"))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    /** The key is stored on the first write, or there is nothing for a replay to match against. */
    @Test
    void theKeyIsStoredWithTheAnswer() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        service.respond(CALLER, MATCH_ID, new RespondRequest("DECLINED"), "a1b2c3");

        org.mockito.ArgumentCaptor<RequestMatch> saved =
                org.mockito.ArgumentCaptor.forClass(RequestMatch.class);
        verify(matches).save(saved.capture());
        assertThat(saved.getValue().getIdempotencyKey()).isEqualTo("a1b2c3");
    }

    /** A live connection has nothing to replay, so it sends no key and the column stays NULL. */
    @Test
    void anOnlineAnswerStoresNoKey() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        service.respond(CALLER, MATCH_ID, new RespondRequest("DECLINED"));

        org.mockito.ArgumentCaptor<RequestMatch> saved =
                org.mockito.ArgumentCaptor.forClass(RequestMatch.class);
        verify(matches).save(saved.capture());
        assertThat(saved.getValue().getIdempotencyKey()).isNull();
    }

    /** FR-NOTIFY-003: an acceptance tells the requester, once, for this request. */
    @Test
    void acceptingPublishesDonorAccepted() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED"));

        org.mockito.ArgumentCaptor<DonorAccepted> published =
                org.mockito.ArgumentCaptor.forClass(DonorAccepted.class);
        verify(events).publishEvent(published.capture());
        assertThat(published.getValue().requestId()).isEqualTo(REQUEST_ID);
    }

    /** A decline is not news the family can act on. */
    @Test
    void decliningPublishesNothing() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        service.respond(CALLER, MATCH_ID, new RespondRequest("DECLINED"));

        verify(events, never()).publishEvent(any());
    }

    /** The replay of an acceptance that already landed already told the family once. */
    @Test
    void replayingAnAcceptancePublishesNothing() {
        RequestMatch answered = unanswered(MY_PROFILE);
        answered.setResponse("ACCEPTED");
        answered.setIdempotencyKey("a1b2c3");
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(answered));

        service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED"), "a1b2c3");

        verify(events, never()).publishEvent(any());
    }

    /** A refused answer changed nothing, so there is nothing to announce. */
    @Test
    void aRejectedAcceptancePublishesNothing() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(SOMEONE_ELSES_PROFILE)));

        assertThatThrownBy(() -> service.respond(CALLER, MATCH_ID, new RespondRequest("ACCEPTED")))
                .isInstanceOf(ApiException.class);

        verify(events, never()).publishEvent(any());
    }

    /**
     * WITHDRAWN is a valid column value with no FR behind it. Accepting it here would create a
     * state nothing in the system knows how to leave.
     */
    @Test
    void withdrawnIsNotAnAnswerThisBuildAccepts() {
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered(MY_PROFILE)));

        assertThatThrownBy(() -> service.respond(CALLER, MATCH_ID, new RespondRequest("WITHDRAWN")))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);

        verify(matches, never()).save(any());
    }

    /** A requester has no donor profile, so they have no inbox and no match to answer. */
    @Test
    void aCallerWithNoDonorProfileHasNoMatches() {
        UUID requester = UUID.randomUUID();
        when(donorProfiles.findByUserId(requester)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.listMine(requester))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    private static RequestMatch unanswered(UUID donorProfileId) {
        RequestMatch match = new RequestMatch();
        match.setDonorProfileId(donorProfileId);
        match.setBloodRequestId(REQUEST_ID);
        return match;
    }
}
