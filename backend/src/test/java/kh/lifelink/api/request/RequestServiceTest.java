package kh.lifelink.api.request;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.notify.RequestAlertNotifier;
import kh.lifelink.api.request.dto.RequestCreateRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;

class RequestServiceTest {

    private static final UUID CREATOR = UUID.randomUUID();
    private static final UUID STRANGER = UUID.randomUUID();
    private static final UUID MATCHED_DONOR_USER = UUID.randomUUID();
    private static final UUID MATCHED_DONOR_PROFILE = UUID.randomUUID();
    private static final UUID REQUEST_ID = UUID.randomUUID();
    private static final UUID DONOR_A = UUID.randomUUID();
    private static final UUID DONOR_B = UUID.randomUUID();

    private BloodRequestRepository requests;
    private DonorProfileRepository donorProfiles;
    private RequestMatchRepository matches;
    private RequestCreation creation;
    private RequestAlertNotifier notifier;
    private RequestRateLimiter rateLimiter;
    private RequestViews views;
    private RequestService service;

    private BloodRequest existing;

    @BeforeEach
    void setUp() {
        requests = mock(BloodRequestRepository.class);
        donorProfiles = mock(DonorProfileRepository.class);
        matches = mock(RequestMatchRepository.class);
        creation = mock(RequestCreation.class);
        notifier = mock(RequestAlertNotifier.class);
        rateLimiter = mock(RequestRateLimiter.class);
        views = mock(RequestViews.class);
        service =
                new RequestService(
                        requests, donorProfiles, matches, creation, notifier, rateLimiter, views);

        when(rateLimiter.tryAcquire(any())).thenReturn(true);

        existing = new BloodRequest();
        existing.setCreatedByUserId(CREATOR);
        existing.setStatus("OPEN");
        existing.setContactName("Sokha");
        existing.setContactPhone("012345678");
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(existing));
        when(requests.save(any())).thenAnswer(call -> call.getArgument(0));
    }

    private void creationReturns(UUID... donorProfileIds) {
        BloodRequest created = new BloodRequest();
        created.setCreatedByUserId(CREATOR);
        created.setPatientBloodType("A+");
        when(creation.createAndMatch(any(), any()))
                .thenReturn(
                        new RequestCreation.Created(
                                created, "Test Hospital", List.of(donorProfileIds)));
    }

    private static RequestCreateRequest body() {
        return new RequestCreateRequest("A+", 1, UUID.randomUUID(), "URGENT", "Sokha", "012345678");
    }

    /**
     * The whole point of keeping the push outside the transaction. An FCM outage must leave a real
     * request behind — the alternative is a 500, a retry, and two requests for one patient.
     */
    @Test
    void anFcmFailureStillProducesARequest() {
        creationReturns(DONOR_A, DONOR_B);
        when(notifier.alert(any(), anyString(), anyString(), any())).thenReturn(Set.of());

        service.create(CREATOR, body());

        verify(creation).createAndMatch(eq(CREATOR), any());
        // Nothing was stamped, which is exactly what a nullable notified_at is for.
        verify(creation).stampNotified(any(), eq(Set.of()));
    }

    /** Only the donors FCM accepted are stamped — not everyone who was matched. */
    @Test
    void onlySuccessfullyNotifiedDonorsAreStamped() {
        creationReturns(DONOR_A, DONOR_B);
        when(notifier.alert(any(), anyString(), anyString(), any())).thenReturn(Set.of(DONOR_A));

        service.create(CREATOR, body());

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Set<UUID>> stamped = ArgumentCaptor.forClass(Set.class);
        verify(creation).stampNotified(any(), stamped.capture());
        assertThat(stamped.getValue()).containsExactly(DONOR_A);
    }

    /** One request fans out to 25 pushes, so an unthrottled account is a spam cannon. */
    @Test
    void aRateLimitedCallerCreatesNothing() {
        when(rateLimiter.tryAcquire(CREATOR)).thenReturn(false);

        assertThatThrownBy(() -> service.create(CREATOR, body()))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        verify(creation, never()).createAndMatch(any(), any());
        verify(notifier, never()).alert(any(), anyString(), anyString(), any());
    }

    /** The creator sees no requesterContact — they already know their own number. */
    @Test
    void theCreatorReadsTheRequestWithoutContactDetails() {
        service.read(CREATOR, REQUEST_ID);

        verify(views).detail(existing, null, null);
    }

    /**
     * 404 rather than 403. A 403 confirms the request exists, which turns this endpoint into an
     * oracle for enumerating blood requests.
     */
    @Test
    void aStrangerCannotTellWhetherARequestExists() {
        when(donorProfiles.findByUserId(STRANGER)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.read(STRANGER, REQUEST_ID))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    /** A matched donor's own response and stored distance are what decide what they see. */
    @Test
    void aMatchedDonorReadsTheRequestThroughTheirOwnMatch() {
        DonorProfile profile = mock(DonorProfile.class);
        when(profile.getId()).thenReturn(MATCHED_DONOR_PROFILE);
        when(donorProfiles.findByUserId(MATCHED_DONOR_USER)).thenReturn(Optional.of(profile));

        RequestMatch match = new RequestMatch();
        match.setResponse("ACCEPTED");
        match.setDistanceKm(new BigDecimal("2.5"));
        when(matches.findByBloodRequestIdAndDonorProfileId(REQUEST_ID, MATCHED_DONOR_PROFILE))
                .thenReturn(Optional.of(match));

        service.read(MATCHED_DONOR_USER, REQUEST_ID);

        verify(views).detail(existing, "ACCEPTED", new BigDecimal("2.5"));
    }

    /** 403 here, unlike read's 404: the caller was given the id, so hiding it would be theatre. */
    @Test
    void onlyTheCreatorCanCancel() {
        assertThatThrownBy(() -> service.cancel(STRANGER, REQUEST_ID))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.FORBIDDEN);

        assertThat(existing.getStatus()).isEqualTo("OPEN");
    }

    @Test
    void cancellingAClosedRequestConflicts() {
        existing.setStatus("CANCELLED");

        assertThatThrownBy(() -> service.cancel(CREATOR, REQUEST_ID))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void theCreatorCanCancelAnOpenRequest() {
        service.cancel(CREATOR, REQUEST_ID);

        assertThat(existing.getStatus()).isEqualTo("CANCELLED");
    }
}
