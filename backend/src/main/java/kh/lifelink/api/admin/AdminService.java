package kh.lifelink.api.admin;

import java.util.List;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.admin.dto.AdminUserResponse;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * TM-AUTH-001 E1 — "HOSPITAL and ADMIN are provisioned by an existing admin" — as an endpoint
 * instead of {@code V8__portal_access.sql}'s hand-run migration. This <strong>promotes an existing
 * self-service account</strong>; it never creates one from a bare name or email, which would reopen
 * the identity-spoofing question S1 already closed (a user's only identity is their verified Google
 * {@code sub}, established by signing in themselves).
 */
@Service
public class AdminService {

    private static final List<String> SELF_SERVICE_ROLES = List.of("DONOR", "REQUESTER");
    private static final List<String> STAFF_ROLES = List.of("HOSPITAL", "ADMIN");

    private final UserRepository users;
    private final HospitalRepository hospitals;

    AdminService(UserRepository users, HospitalRepository hospitals) {
        this.users = users;
        this.hospitals = hospitals;
    }

    /**
     * Everyone an ADMIN could promote. Filtered to accounts with a {@code display_name} — without
     * one there is nothing to tell two candidates apart by, and showing a bare UUID invites picking
     * the wrong person.
     */
    @Transactional(readOnly = true)
    public List<AdminUserResponse> listCandidates() {
        return users.findByRoleInOrderByDisplayNameAsc(SELF_SERVICE_ROLES).stream()
                .filter(user -> user.getDisplayName() != null)
                .map(
                        user ->
                                new AdminUserResponse(
                                        user.getId(), user.getDisplayName(), user.getRole()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StaffResponse> listStaff() {
        List<User> staff = users.findByRoleInOrderByDisplayNameAsc(STAFF_ROLES);
        var hospitalsById = hospitalsById(staff);
        return staff.stream().map(user -> toStaffResponse(user, hospitalsById)).toList();
    }

    /**
     * The one write. Sets role and hospital scope on an existing row — the same two fields {@code
     * V8__portal_access.sql}'s seed sets by hand, now set by an authenticated ADMIN through the
     * app.
     */
    @Transactional
    public StaffResponse assignStaffRole(AssignStaffRoleRequest body) {
        if (!STAFF_ROLES.contains(body.role())) {
            throw ApiException.unprocessable("INVALID_ROLE", "role must be HOSPITAL or ADMIN.");
        }
        if ("HOSPITAL".equals(body.role()) && body.hospitalId() == null) {
            throw ApiException.unprocessable(
                    "HOSPITAL_ID_REQUIRED", "hospitalId is required when role is HOSPITAL.");
        }
        if ("ADMIN".equals(body.role()) && body.hospitalId() != null) {
            throw ApiException.unprocessable(
                    "HOSPITAL_ID_NOT_ALLOWED", "ADMIN is not scoped to one hospital.");
        }

        User user =
                users.findById(body.userId())
                        .orElseThrow(
                                () -> ApiException.notFound("USER_NOT_FOUND", "No such user."));

        if (STAFF_ROLES.contains(user.getRole())) {
            // Not idempotent on purpose: re-provisioning an existing staff account (a hospital
            // transfer, say) is a deliberate action with its own trail, not a side effect of
            // clicking the same button twice.
            throw ApiException.unprocessable(
                    "ALREADY_STAFF", "This account is already HOSPITAL or ADMIN.");
        }

        Hospital hospital = null;
        if (body.hospitalId() != null) {
            hospital =
                    hospitals
                            .findById(body.hospitalId())
                            .orElseThrow(
                                    () ->
                                            ApiException.notFound(
                                                    "HOSPITAL_NOT_FOUND", "No such hospital."));
        }

        user.setRole(body.role());
        user.setHospitalId(body.hospitalId());

        return new StaffResponse(
                user.getId(),
                user.getDisplayName(),
                user.getRole(),
                user.getHospitalId(),
                hospital == null ? null : hospital.getName());
    }

    private java.util.Map<java.util.UUID, Hospital> hospitalsById(List<User> staff) {
        List<java.util.UUID> ids =
                staff.stream()
                        .map(User::getHospitalId)
                        .filter(Objects::nonNull)
                        .distinct()
                        .toList();
        return hospitals.findAllById(ids).stream()
                .collect(Collectors.toMap(Hospital::getId, Function.identity()));
    }

    private StaffResponse toStaffResponse(
            User user, java.util.Map<java.util.UUID, Hospital> hospitalsById) {
        Hospital hospital =
                user.getHospitalId() == null ? null : hospitalsById.get(user.getHospitalId());
        return new StaffResponse(
                user.getId(),
                user.getDisplayName(),
                user.getRole(),
                user.getHospitalId(),
                hospital == null ? null : hospital.getName());
    }
}
