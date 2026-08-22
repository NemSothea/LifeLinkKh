package kh.lifelink.api.portal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.donation.Donation;
import kh.lifelink.api.donation.DonationRepository;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.portal.dto.ConfirmDonationRequest;
import kh.lifelink.api.portal.dto.ConfirmDonationResponse;
import kh.lifelink.api.portal.dto.PortalRequestResponse;
import kh.lifelink.api.request.BloodRequest;
import kh.lifelink.api.request.BloodRequestRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

/** FR-PORTAL-001, trimmed by DEC-004: the open-requests table and confirm-donation. */
class PortalServiceTest {

    private static final UUID HOSPITAL_STAFF = UUID.randomUUID();
    private static final UUID ADMIN_USER = UUID.randomUUID();
    private static final UUID CALMETTE = UUID.randomUUID();
    private static final UUID OTHER_HOSPITAL = UUID.randomUUID();
    private static final UUID REQUEST_ID = UUID.randomUUID();
    private static final UUID MATCH_ID = UUID.randomUUID();
    private static final UUID DONOR_PROFILE_ID = UUID.randomUUID();

    private BloodRequestRepository requests;
    private RequestMatchRepository matches;
    private DonorProfileRepository donorProfiles;
    private DonationRepository donations;
    private UserRepository users;
    private HospitalRepository hospitals;
    private DistrictRepository districts;
    private PortalService service;

    @BeforeEach
    void setUp() {
        requests = mock(BloodRequestRepository.class);
        matches = mock(RequestMatchRepository.class);
        donorProfiles = mock(DonorProfileRepository.class);
        donations = mock(DonationRepository.class);
        users = mock(UserRepository.class);
        hospitals = mock(HospitalRepository.class);
        districts = mock(DistrictRepository.class);
        service = new PortalService(requests, matches, donorProfiles, donations, users, hospitals, districts);

        when(hospitals.findAllById(any())).thenReturn(List.of());
        when(districts.findAll()).thenReturn(List.of());
        when(matches.findByBloodRequestIdAndResponse(any(), any())).thenReturn(List.of());
        when(matches.countByBloodRequestId(any())).thenReturn(0);

        User hospitalStaff = hospitalUser(HOSPITAL_STAFF, CALMETTE);
        when(users.findById(HOSPITAL_STAFF)).thenReturn(Optional.of(hospitalStaff));

        User admin = new User();
        admin.setRole("ADMIN");
        when(users.findById(ADMIN_USER)).thenReturn(Optional.of(admin));
    }

    @Test
    void anythingOtherThanOpenIsRefused() {
        assertThatThrownBy(() -> service.listRequests(HOSPITAL_STAFF, "FULFILLED"))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    @Test
    void hospitalStaffOnlySeeTheirOwnHospitalsRequests() {
        when(requests.findByStatusAndHospitalIdOrderByCreatedAtDesc("OPEN", CALMETTE))
                .thenReturn(List.of(openRequest(CALMETTE)));

        List<PortalRequestResponse> result = service.listRequests(HOSPITAL_STAFF, "OPEN");

        assertThat(result).hasSize(1);
        verify(requests, never()).findByStatusOrderByCreatedAtDesc(any());
    }

    @Test
    void adminSeesEveryHospital() {
        when(requests.findByStatusOrderByCreatedAtDesc("OPEN"))
                .thenReturn(List.of(openRequest(CALMETTE), openRequest(OTHER_HOSPITAL)));

        List<PortalRequestResponse> result = service.listRequests(ADMIN_USER, "OPEN");

        assertThat(result).hasSize(2);
        verify(requests, never()).findByStatusAndHospitalIdOrderByCreatedAtDesc(any(), any());
    }

    @Test
    void acceptedDonorsAreOrderedByWhenTheyAnswered() {
        when(requests.findByStatusAndHospitalIdOrderByCreatedAtDesc("OPEN", CALMETTE))
                .thenReturn(List.of(openRequest(CALMETTE)));

        UUID laterProfile = UUID.randomUUID();
        RequestMatch early = acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now().minusMinutes(10));
        RequestMatch late = acceptedMatch(laterProfile, OffsetDateTime.now());
        when(matches.findByBloodRequestIdAndResponse(REQUEST_ID, "ACCEPTED"))
                .thenReturn(List.of(late, early));

        DonorProfile a = donorProfile(DONOR_PROFILE_ID, "Sophea");
        DonorProfile b = donorProfile(laterProfile, "Dara");
        when(donorProfiles.findById(DONOR_PROFILE_ID)).thenReturn(Optional.of(a));
        when(donorProfiles.findById(laterProfile)).thenReturn(Optional.of(b));

        List<PortalRequestResponse> result = service.listRequests(HOSPITAL_STAFF, "OPEN");

        assertThat(result.get(0).acceptedDonors())
                .extracting(d -> d.displayName())
                .containsExactly("Sophea", "Dara");
    }

    @Test
    void aConfirmedDonorDropsOffTheActionableListButStaysInTheCount() {
        when(requests.findByStatusAndHospitalIdOrderByCreatedAtDesc("OPEN", CALMETTE))
                .thenReturn(List.of(openRequest(CALMETTE)));

        UUID confirmedProfile = UUID.randomUUID();
        RequestMatch pending = acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now());
        RequestMatch confirmed = acceptedMatch(confirmedProfile, OffsetDateTime.now());
        when(matches.findByBloodRequestIdAndResponse(REQUEST_ID, "ACCEPTED"))
                .thenReturn(List.of(pending, confirmed));
        when(donorProfiles.findById(DONOR_PROFILE_ID))
                .thenReturn(Optional.of(donorProfile(DONOR_PROFILE_ID, "Sophea")));
        when(donations.existsByDonorProfileIdAndBloodRequestId(confirmedProfile, REQUEST_ID))
                .thenReturn(true);

        List<PortalRequestResponse> result = service.listRequests(HOSPITAL_STAFF, "OPEN");

        assertThat(result.get(0).acceptedCount()).isEqualTo(2);
        assertThat(result.get(0).acceptedDonors())
                .extracting(d -> d.displayName())
                .containsExactly("Sophea");
    }

    @Test
    void aFutureDonationDateIsRefused() {
        assertThatThrownBy(
                        () ->
                                service.confirmDonation(
                                        HOSPITAL_STAFF,
                                        REQUEST_ID,
                                        new ConfirmDonationRequest(
                                                MATCH_ID, LocalDate.now().plusDays(1))))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    @Test
    void confirmingAgainstAnotherHospitalsRequestIsForbidden() {
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(openRequest(OTHER_HOSPITAL)));

        assertThatThrownBy(
                        () ->
                                service.confirmDonation(
                                        HOSPITAL_STAFF,
                                        REQUEST_ID,
                                        new ConfirmDonationRequest(MATCH_ID, LocalDate.now())))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.FORBIDDEN);

        verify(donations, never()).save(any());
    }

    @Test
    void aMatchThatNeverAcceptedCannotBeConfirmed() {
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(openRequest(CALMETTE)));
        RequestMatch unanswered = new RequestMatch();
        unanswered.setBloodRequestId(REQUEST_ID);
        unanswered.setDonorProfileId(DONOR_PROFILE_ID);
        when(matches.findById(MATCH_ID)).thenReturn(Optional.of(unanswered));

        assertThatThrownBy(
                        () ->
                                service.confirmDonation(
                                        HOSPITAL_STAFF,
                                        REQUEST_ID,
                                        new ConfirmDonationRequest(MATCH_ID, LocalDate.now())))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void confirmingTheSameDonationTwiceConflicts() {
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(openRequest(CALMETTE)));
        when(matches.findById(MATCH_ID))
                .thenReturn(Optional.of(acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now())));
        when(donations.existsByDonorProfileIdAndBloodRequestId(DONOR_PROFILE_ID, REQUEST_ID))
                .thenReturn(true);

        assertThatThrownBy(
                        () ->
                                service.confirmDonation(
                                        HOSPITAL_STAFF,
                                        REQUEST_ID,
                                        new ConfirmDonationRequest(MATCH_ID, LocalDate.now())))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.CONFLICT);

        verify(donations, never()).save(any());
    }

    @Test
    void confirmingWritesTheDonationAndRefreshesTheCache() {
        BloodRequest request = openRequest(CALMETTE);
        request.setUnitsNeeded((short) 1);
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(request));
        when(matches.findById(MATCH_ID))
                .thenReturn(Optional.of(acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now())));
        when(donations.existsByDonorProfileIdAndBloodRequestId(DONOR_PROFILE_ID, REQUEST_ID))
                .thenReturn(false);
        DonorProfile profile = donorProfile(DONOR_PROFILE_ID, "Sophea");
        when(donorProfiles.findById(DONOR_PROFILE_ID)).thenReturn(Optional.of(profile));
        Donation saved = new Donation();
        saved.setDonatedOn(LocalDate.now());
        when(donations.save(any())).thenReturn(saved);
        when(donations.countByBloodRequestId(REQUEST_ID)).thenReturn(1);

        ConfirmDonationResponse response =
                service.confirmDonation(
                        HOSPITAL_STAFF,
                        REQUEST_ID,
                        new ConfirmDonationRequest(MATCH_ID, LocalDate.now()));

        assertThat(response.donorDisplayName()).isEqualTo("Sophea");
        assertThat(response.requestStatus()).isEqualTo("FULFILLED");
        assertThat(response.donorNextEligibleOn()).isEqualTo(LocalDate.now().plusDays(56));
        assertThat(profile.getLastDonationDate()).isEqualTo(LocalDate.now());
        verify(requests).save(request);
    }

    @Test
    void requestStaysOpenWhileUnitsAreStillNeeded() {
        BloodRequest request = openRequest(CALMETTE);
        request.setUnitsNeeded((short) 2);
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(request));
        when(matches.findById(MATCH_ID))
                .thenReturn(Optional.of(acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now())));
        when(donations.existsByDonorProfileIdAndBloodRequestId(any(), any())).thenReturn(false);
        when(donorProfiles.findById(DONOR_PROFILE_ID))
                .thenReturn(Optional.of(donorProfile(DONOR_PROFILE_ID, "Sophea")));
        when(donations.save(any())).thenAnswer(call -> call.getArgument(0));
        when(donations.countByBloodRequestId(REQUEST_ID)).thenReturn(1);

        service.confirmDonation(
                HOSPITAL_STAFF, REQUEST_ID, new ConfirmDonationRequest(MATCH_ID, LocalDate.now()));

        assertThat(request.getStatus()).isEqualTo("OPEN");
        verify(requests, never()).save(any());
    }

    @Test
    void confirmingAnOlderBackdatedDonationDoesNotRegressTheCache() {
        BloodRequest request = openRequest(CALMETTE);
        request.setUnitsNeeded((short) 5);
        when(requests.findById(REQUEST_ID)).thenReturn(Optional.of(request));
        when(matches.findById(MATCH_ID))
                .thenReturn(Optional.of(acceptedMatch(DONOR_PROFILE_ID, OffsetDateTime.now())));
        when(donations.existsByDonorProfileIdAndBloodRequestId(any(), any())).thenReturn(false);
        DonorProfile profile = donorProfile(DONOR_PROFILE_ID, "Sophea");
        profile.setLastDonationDate(LocalDate.now());
        when(donorProfiles.findById(DONOR_PROFILE_ID)).thenReturn(Optional.of(profile));
        when(donations.save(any())).thenAnswer(call -> call.getArgument(0));
        when(donations.countByBloodRequestId(REQUEST_ID)).thenReturn(1);

        service.confirmDonation(
                HOSPITAL_STAFF,
                REQUEST_ID,
                new ConfirmDonationRequest(MATCH_ID, LocalDate.now().minusDays(30)));

        assertThat(profile.getLastDonationDate()).isEqualTo(LocalDate.now());
        verify(donorProfiles, never()).save(any());
    }

    private static User hospitalUser(UUID id, UUID hospitalId) {
        User user = new User();
        user.setRole("HOSPITAL");
        user.setHospitalId(hospitalId);
        return user;
    }

    private static BloodRequest openRequest(UUID hospitalId) {
        BloodRequest request = new BloodRequest();
        request.setHospitalId(hospitalId);
        request.setPatientBloodType("A+");
        request.setUnitsNeeded((short) 1);
        request.setUrgency("URGENT");
        request.setStatus("OPEN");
        // @GeneratedValue has no setter; a real JPA load always populates it, so tests that read
        // it back (listRequests) need it set the same way AuthServiceTest sets a mock id.
        ReflectionTestUtils.setField(request, "id", REQUEST_ID);
        return request;
    }

    private static RequestMatch acceptedMatch(UUID donorProfileId, OffsetDateTime respondedAt) {
        RequestMatch match = new RequestMatch();
        match.setBloodRequestId(REQUEST_ID);
        match.setDonorProfileId(donorProfileId);
        match.setResponse("ACCEPTED");
        match.setRespondedAt(respondedAt);
        return match;
    }

    private static DonorProfile donorProfile(UUID id, String fullName) {
        DonorProfile profile = new DonorProfile();
        profile.setFullName(fullName);
        profile.setBloodType("O-");
        profile.setDistrictCode("1204");
        ReflectionTestUtils.setField(profile, "id", id);
        return profile;
    }
}
