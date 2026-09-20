package kh.lifelink.api.admin;

import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.admin.dto.AdminUserResponse;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.CreateStaffAccountRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
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

    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private static final List<String> SELF_SERVICE_ROLES = List.of("DONOR", "REQUESTER");
    private static final List<String> STAFF_ROLES = List.of("HOSPITAL", "ADMIN");

    private final UserRepository users;
    private final HospitalRepository hospitals;
    private final PasswordEncoder passwords;

    AdminService(UserRepository users, HospitalRepository hospitals, PasswordEncoder passwords) {
        this.users = users;
        this.hospitals = hospitals;
        this.passwords = passwords;
    }

    /**
     * Creates a portal account outright, rather than promoting one that already exists.
     *
     * <p>Both paths are needed and neither replaces the other. Promotion is right for someone who
     * already uses the mobile app — it keeps their verified Google identity and their history. This
     * is right for a desk-only account with no phone in the loop, which promotion cannot reach
     * because there is no row to promote; before this existed such an account could only be created
     * by writing a Flyway migration.
     *
     * <p>Role rules are the promote endpoint's, unchanged: HOSPITAL needs a hospital, ADMIN must
     * not have one. Enforcing them in one shape in two places is deliberate — a caller must not be
     * able to create through this door something the other door would refuse.
     */
    @Transactional
    public StaffResponse createStaffAccount(CreateStaffAccountRequest body) {
        String role = body.role();
        if (!STAFF_ROLES.contains(role)) {
            throw ApiException.unprocessable("INVALID_ROLE", "role must be HOSPITAL or ADMIN.");
        }
        if ("HOSPITAL".equals(role) && body.hospitalId() == null) {
            throw ApiException.unprocessable(
                    "HOSPITAL_ID_REQUIRED", "hospitalId is required when role is HOSPITAL.");
        }
        if ("ADMIN".equals(role) && body.hospitalId() != null) {
            throw ApiException.unprocessable(
                    "HOSPITAL_ID_NOT_ALLOWED", "ADMIN is not scoped to one hospital.");
        }

        String username = body.username().trim();
        if (users.findByUsername(username).isPresent()) {
            // A distinguishable answer, unlike sign-in's: this caller is an authenticated ADMIN
            // who is allowed to know which usernames are taken, and hiding it would only make
            // them guess why the form failed.
            throw ApiException.unprocessable("USERNAME_TAKEN", "That username is already in use.");
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

        User user = new User();
        user.setUsername(username);
        // Hashed here and nowhere else. The plaintext exists only inside this method's argument.
        user.setPasswordHash(passwords.encode(body.password()));
        user.setDisplayName(body.displayName().trim());
        user.setRole(role);
        user.setHospitalId(body.hospitalId());
        User saved = users.save(user);

        // The username, never the password, and never a hash.
        log.info(
                "staff account created user={} username={} role={}", saved.getId(), username, role);
        return new StaffResponse(
                saved.getId(),
                saved.getDisplayName(),
                saved.getRole(),
                saved.getHospitalId(),
                hospital == null ? null : hospital.getName());
    }

    /**
     * Demotes an ADMIN to hospital staff, scoped to one hospital.
     *
     * <p>The only demotion that means anything here: there are two staff roles, and the other
     * direction is what {@code assignStaffRole} already does. Taking someone out of staff entirely
     * is {@link #revokeStaffAccess}.
     */
    @Transactional
    public StaffResponse demoteToHospitalStaff(UUID callerId, UUID targetId, UUID hospitalId) {
        User target = requireStaff(targetId);

        if (!"ADMIN".equals(target.getRole())) {
            throw ApiException.unprocessable(
                    "NOT_AN_ADMIN", "Only an ADMIN account can be demoted.");
        }
        refuseSelf(callerId, targetId, "You cannot change your own access level.");
        refuseLastAdmin(target);

        if (hospitalId == null) {
            throw ApiException.unprocessable(
                    "HOSPITAL_ID_REQUIRED", "hospitalId is required when role is HOSPITAL.");
        }
        Hospital hospital =
                hospitals
                        .findById(hospitalId)
                        .orElseThrow(
                                () ->
                                        ApiException.notFound(
                                                "HOSPITAL_NOT_FOUND", "No such hospital."));

        target.setRole("HOSPITAL");
        target.setHospitalId(hospitalId);
        log.info("staff demoted user={} by={} hospital={}", targetId, callerId, hospitalId);
        return new StaffResponse(
                target.getId(),
                target.getDisplayName(),
                target.getRole(),
                target.getHospitalId(),
                hospital.getName());
    }

    /**
     * Removes portal access. What that means depends on how the account can authenticate, and the
     * difference matters:
     *
     * <ul>
     *   <li>An account that was <strong>promoted</strong> from the mobile app still has its Google
     *       or Telegram credential, so it goes back to {@code DONOR} and keeps working as an
     *       ordinary app account. Nothing is destroyed.
     *   <li>A <strong>portal-only</strong> account has nowhere to go back to — it exists only to
     *       sign in here — so it is deactivated instead. The row stays because {@code
     *       donations.confirmed_by_user_id} points at it; deleting it would either fail on the
     *       foreign key or erase who confirmed a donation.
     * </ul>
     */
    @Transactional
    public void revokeStaffAccess(UUID callerId, UUID targetId) {
        User target = requireStaff(targetId);
        refuseSelf(callerId, targetId, "You cannot revoke your own access.");
        refuseLastAdmin(target);

        boolean canStillAuthenticateElsewhere =
                target.getFirebaseUid() != null || target.getTelegramChatId() != null;

        if (canStillAuthenticateElsewhere) {
            target.setRole("DONOR");
            target.setHospitalId(null);
            log.info(
                    "staff access revoked user={} by={} outcome=RETURNED_TO_DONOR",
                    targetId,
                    callerId);
        } else {
            target.setDeactivatedAt(java.time.OffsetDateTime.now());
            target.setHospitalId(null);
            log.info("staff access revoked user={} by={} outcome=DEACTIVATED", targetId, callerId);
        }
    }

    private User requireStaff(UUID userId) {
        User user =
                users.findById(userId)
                        .orElseThrow(
                                () -> ApiException.notFound("USER_NOT_FOUND", "No such user."));
        if (!STAFF_ROLES.contains(user.getRole()) || user.getDeactivatedAt() != null) {
            throw ApiException.unprocessable(
                    "NOT_STAFF", "That account does not have portal access.");
        }
        return user;
    }

    /**
     * An admin acting on their own account is the one move that cannot be undone from inside the
     * product: demote or revoke yourself and the page you would fix it from is the page you just
     * lost. There is no password reset and no second channel (ADR 0002), so recovery is a database
     * change. Refused rather than confirmed-with-a-warning.
     */
    private void refuseSelf(UUID callerId, UUID targetId, String message) {
        if (callerId.equals(targetId)) {
            throw ApiException.unprocessable("CANNOT_TARGET_SELF", message);
        }
    }

    /**
     * The same trap one step removed: two admins who each revoke the other, or one admin revoking
     * the only other one and then losing their own password. With no ADMIN left, nobody can grant
     * access to anyone ever again.
     */
    private void refuseLastAdmin(User target) {
        if ("ADMIN".equals(target.getRole())
                && users.countByRoleAndDeactivatedAtIsNull("ADMIN") <= 1) {
            throw ApiException.unprocessable(
                    "LAST_ADMIN", "This is the only administrator. Grant another one first.");
        }
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
        List<User> staff =
                users.findByRoleInOrderByDisplayNameAsc(STAFF_ROLES).stream()
                        // A deactivated account is not staff any more; it is kept only so the
                        // donations it confirmed still name who confirmed them.
                        .filter(user -> user.getDeactivatedAt() == null)
                        .toList();
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
