package kh.lifelink.api.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.CreateStaffAccountRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

/** TM-AUTH-001 E1 as an endpoint: an ADMIN promotes an existing self-service account. */
class AdminServiceTest {

    private static final UUID CALMETTE = UUID.randomUUID();

    private UserRepository users;
    private HospitalRepository hospitals;
    private AdminService service;

    @BeforeEach
    void setUp() {
        users = mock(UserRepository.class);
        hospitals = mock(HospitalRepository.class);
        service = new AdminService(users, hospitals, new BCryptPasswordEncoder());
    }

    private User donor(UUID id, String displayName) {
        User user = new User();
        ReflectionTestUtils.setField(user, "id", id);
        user.setRole("DONOR");
        user.setDisplayName(displayName);
        return user;
    }

    @Test
    void listCandidates_omits_accounts_with_no_display_name() {
        User named = donor(UUID.randomUUID(), "Sok Dara");
        User unnamed = donor(UUID.randomUUID(), null);
        when(users.findByRoleInOrderByDisplayNameAsc(List.of("DONOR", "REQUESTER")))
                .thenReturn(List.of(named, unnamed));

        var result = service.listCandidates();

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().displayName()).isEqualTo("Sok Dara");
    }

    @Test
    void assignStaffRole_promotes_a_donor_to_hospital_staff() {
        User user = donor(UUID.randomUUID(), "Chea Srey");
        when(users.findById(user.getId())).thenReturn(Optional.of(user));
        Hospital calmette = new Hospital();
        ReflectionTestUtils.setField(calmette, "id", CALMETTE);
        ReflectionTestUtils.setField(calmette, "name", "Calmette Hospital");
        when(hospitals.findById(CALMETTE)).thenReturn(Optional.of(calmette));

        StaffResponse result =
                service.assignStaffRole(
                        new AssignStaffRoleRequest(user.getId(), "HOSPITAL", CALMETTE));

        assertThat(result.role()).isEqualTo("HOSPITAL");
        assertThat(result.hospitalId()).isEqualTo(CALMETTE);
        assertThat(result.hospitalName()).isEqualTo("Calmette Hospital");
        assertThat(user.getRole()).isEqualTo("HOSPITAL");
        assertThat(user.getHospitalId()).isEqualTo(CALMETTE);
    }

    @Test
    void assignStaffRole_admin_must_not_carry_a_hospital_id() {
        User user = donor(UUID.randomUUID(), "Oun Sreynich");
        when(users.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(
                        () ->
                                service.assignStaffRole(
                                        new AssignStaffRoleRequest(
                                                user.getId(), "ADMIN", CALMETTE)))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
                            assertThat(ex.getCode()).isEqualTo("HOSPITAL_ID_NOT_ALLOWED");
                        });
    }

    @Test
    void assignStaffRole_hospital_requires_a_hospital_id() {
        User user = donor(UUID.randomUUID(), "Moeun Nithvaraman");
        when(users.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(
                        () ->
                                service.assignStaffRole(
                                        new AssignStaffRoleRequest(user.getId(), "HOSPITAL", null)))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("HOSPITAL_ID_REQUIRED"));
    }

    @Test
    void assignStaffRole_refuses_an_account_already_on_staff() {
        User staff = donor(UUID.randomUUID(), "Suon Pisey");
        staff.setRole("HOSPITAL");
        when(users.findById(staff.getId())).thenReturn(Optional.of(staff));

        assertThatThrownBy(
                        () ->
                                service.assignStaffRole(
                                        new AssignStaffRoleRequest(
                                                staff.getId(), "HOSPITAL", CALMETTE)))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("ALREADY_STAFF"));
    }

    @Test
    void assignStaffRole_refuses_an_unknown_hospital() {
        User user = donor(UUID.randomUUID(), "Nem Sothea");
        when(users.findById(user.getId())).thenReturn(Optional.of(user));
        UUID unknownHospital = UUID.randomUUID();
        when(hospitals.findById(unknownHospital)).thenReturn(Optional.empty());

        assertThatThrownBy(
                        () ->
                                service.assignStaffRole(
                                        new AssignStaffRoleRequest(
                                                user.getId(), "HOSPITAL", unknownHospital)))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
                            assertThat(ex.getCode()).isEqualTo("HOSPITAL_NOT_FOUND");
                        });
    }

    @Test
    void assignStaffRole_refuses_an_invalid_role() {
        User user = donor(UUID.randomUUID(), "Sourn Savourn");
        when(users.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(
                        () ->
                                service.assignStaffRole(
                                        new AssignStaffRoleRequest(user.getId(), "DONOR", null)))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("INVALID_ROLE"));
    }

    // ---------------------------------------------------------------------------
    // Creating a portal account outright
    // ---------------------------------------------------------------------------

    @Test
    void createsAStaffAccountWithAHashedPassword() {
        UUID hospitalId = UUID.randomUUID();
        Hospital hospital = new Hospital();
        hospital.setName("Calmette Hospital");
        when(hospitals.findById(hospitalId)).thenReturn(Optional.of(hospital));
        when(users.findByUsername("clerk")).thenReturn(Optional.empty());
        when(users.save(any(User.class))).thenAnswer(call -> call.getArgument(0));

        StaffResponse created =
                service.createStaffAccount(
                        new CreateStaffAccountRequest(
                                "clerk", "a-good-password", "Clerk", "HOSPITAL", hospitalId));

        assertThat(created.role()).isEqualTo("HOSPITAL");
        assertThat(created.hospitalName()).isEqualTo("Calmette Hospital");

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(users).save(saved.capture());
        // The plaintext must not reach the row, and the digest must verify.
        assertThat(saved.getValue().getPasswordHash()).isNotEqualTo("a-good-password");
        assertThat(
                        new BCryptPasswordEncoder()
                                .matches("a-good-password", saved.getValue().getPasswordHash()))
                .isTrue();
    }

    @Test
    void refusesAUsernameThatIsAlreadyTaken() {
        when(users.findByUsername("clerk")).thenReturn(Optional.of(new User()));

        assertThatThrownBy(
                        () ->
                                service.createStaffAccount(
                                        new CreateStaffAccountRequest(
                                                "clerk",
                                                "a-good-password",
                                                "Clerk",
                                                "ADMIN",
                                                null)))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
        verify(users, never()).save(any());
    }

    /**
     * The same role rules as promotion — a caller must not reach through this door what the other
     * refuses.
     */
    @Test
    void refusesHospitalStaffWithNoHospital() {
        when(users.findByUsername("clerk")).thenReturn(Optional.empty());

        assertThatThrownBy(
                        () ->
                                service.createStaffAccount(
                                        new CreateStaffAccountRequest(
                                                "clerk",
                                                "a-good-password",
                                                "Clerk",
                                                "HOSPITAL",
                                                null)))
                .isInstanceOf(ApiException.class);
        verify(users, never()).save(any());
    }

    @Test
    void refusesAnAdminScopedToAHospital() {
        when(users.findByUsername("boss")).thenReturn(Optional.empty());

        assertThatThrownBy(
                        () ->
                                service.createStaffAccount(
                                        new CreateStaffAccountRequest(
                                                "boss",
                                                "a-good-password",
                                                "Boss",
                                                "ADMIN",
                                                UUID.randomUUID())))
                .isInstanceOf(ApiException.class);
        verify(users, never()).save(any());
    }

    @Test
    void refusesARoleThatIsNotStaff() {
        assertThatThrownBy(
                        () ->
                                service.createStaffAccount(
                                        new CreateStaffAccountRequest(
                                                "someone",
                                                "a-good-password",
                                                "Someone",
                                                "DONOR",
                                                null)))
                .isInstanceOf(ApiException.class);
        verify(users, never()).save(any());
    }

    // ---------------------------------------------------------------------------
    // Demote and revoke
    // ---------------------------------------------------------------------------

    private User staff(String role, UUID id) {
        User user = new User();
        user.setRole(role);
        user.setDisplayName(role + " account");
        ReflectionTestUtils.setField(user, "id", id);
        when(users.findById(id)).thenReturn(Optional.of(user));
        return user;
    }

    @Test
    void demotesAnAdminToHospitalStaff() {
        UUID caller = UUID.randomUUID();
        UUID target = UUID.randomUUID();
        UUID hospitalId = UUID.randomUUID();
        User admin = staff("ADMIN", target);
        Hospital hospital = new Hospital();
        hospital.setName("Calmette Hospital");
        when(hospitals.findById(hospitalId)).thenReturn(Optional.of(hospital));
        when(users.countByRoleAndDeactivatedAtIsNull("ADMIN")).thenReturn(2L);

        StaffResponse result = service.demoteToHospitalStaff(caller, target, hospitalId);

        assertThat(result.role()).isEqualTo("HOSPITAL");
        assertThat(admin.getHospitalId()).isEqualTo(hospitalId);
    }

    /**
     * The one move that cannot be undone from inside the product: the page you would fix it from is
     * the page you just lost, and there is no password reset to recover through.
     */
    @Test
    void anAdminCannotDemoteThemselves() {
        UUID self = UUID.randomUUID();
        staff("ADMIN", self);

        assertThatThrownBy(() -> service.demoteToHospitalStaff(self, self, UUID.randomUUID()))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    /** With no ADMIN left, nobody can ever grant access to anyone again. */
    @Test
    void theLastAdminCannotBeRevoked() {
        UUID caller = UUID.randomUUID();
        UUID target = UUID.randomUUID();
        staff("ADMIN", target);
        when(users.countByRoleAndDeactivatedAtIsNull("ADMIN")).thenReturn(1L);

        assertThatThrownBy(() -> service.revokeStaffAccess(caller, target))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    /**
     * A promoted account keeps its Google credential, so it goes back to being an ordinary donor.
     */
    @Test
    void revokingAPromotedAccountReturnsItToDonor() {
        UUID caller = UUID.randomUUID();
        UUID target = UUID.randomUUID();
        User promoted = staff("HOSPITAL", target);
        promoted.setFirebaseUid("google-sub-123");
        promoted.setHospitalId(UUID.randomUUID());

        service.revokeStaffAccess(caller, target);

        assertThat(promoted.getRole()).isEqualTo("DONOR");
        assertThat(promoted.getHospitalId()).isNull();
        assertThat(promoted.getDeactivatedAt()).isNull();
    }

    /**
     * A portal-only account has nowhere to go back to, and the row cannot be deleted — donations it
     * confirmed reference it. Switched off instead.
     */
    @Test
    void revokingAPortalOnlyAccountDeactivatesItRatherThanDeletingIt() {
        UUID caller = UUID.randomUUID();
        UUID target = UUID.randomUUID();
        User portalOnly = staff("HOSPITAL", target);
        portalOnly.setUsername("clerk");
        portalOnly.setPasswordHash("$2a$10$whatever");

        service.revokeStaffAccess(caller, target);

        assertThat(portalOnly.getDeactivatedAt()).isNotNull();
        assertThat(portalOnly.getRole()).isEqualTo("HOSPITAL");
        verify(users, never()).delete(any());
    }

    @Test
    void anAlreadyRevokedAccountCannotBeRevokedTwice() {
        UUID caller = UUID.randomUUID();
        UUID target = UUID.randomUUID();
        User gone = staff("HOSPITAL", target);
        gone.setDeactivatedAt(java.time.OffsetDateTime.now());

        assertThatThrownBy(() -> service.revokeStaffAccess(caller, target))
                .isInstanceOf(ApiException.class);
    }
}
