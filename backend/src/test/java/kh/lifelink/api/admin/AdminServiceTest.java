package kh.lifelink.api.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
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
        service = new AdminService(users, hospitals);
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
}
