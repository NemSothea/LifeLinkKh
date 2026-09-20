package kh.lifelink.api.admin;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.admin.dto.AdminUserResponse;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.CreateStaffAccountRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Staff account management (TM-AUTH-001 E1). {@code SecurityConfig} restricts every {@code
 * /admin/**} path to {@code ADMIN} — a {@code HOSPITAL}, {@code DONOR} or {@code REQUESTER} JWT
 * reaching here gets a 403 before this class ever runs, same shape as {@code PortalController}.
 */
@RestController
@RequestMapping("/admin")
public class AdminController {

    private final AdminService admin;

    AdminController(AdminService admin) {
        this.admin = admin;
    }

    @GetMapping("/users")
    List<AdminUserResponse> candidates() {
        return admin.listCandidates();
    }

    @GetMapping("/staff")
    List<StaffResponse> staff() {
        return admin.listStaff();
    }

    /**
     * Creates a portal account with a username and password, for staff who have no mobile account.
     */
    @PostMapping("/staff/accounts")
    @org.springframework.web.bind.annotation.ResponseStatus(
            org.springframework.http.HttpStatus.CREATED)
    StaffResponse createStaffAccount(@Valid @RequestBody CreateStaffAccountRequest body) {
        return admin.createStaffAccount(body);
    }

    @PostMapping("/staff")
    StaffResponse assignStaffRole(@Valid @RequestBody AssignStaffRoleRequest body) {
        return admin.assignStaffRole(body);
    }

    /** ADMIN to hospital staff. The caller's own id comes from the JWT, never the body. */
    @PostMapping("/staff/{id}/demote")
    StaffResponse demote(
            @AuthenticationPrincipal UUID callerId,
            @PathVariable("id") UUID targetId,
            @RequestBody kh.lifelink.api.admin.dto.DemoteStaffRequest body) {
        return admin.demoteToHospitalStaff(callerId, targetId, body.hospitalId());
    }

    /**
     * Removes portal access entirely. See {@code AdminService.revokeStaffAccess} for what that
     * means.
     */
    @PostMapping("/staff/{id}/revoke")
    ResponseEntity<Void> revoke(
            @AuthenticationPrincipal UUID callerId, @PathVariable("id") UUID targetId) {
        admin.revokeStaffAccess(callerId, targetId);
        return ResponseEntity.noContent().build();
    }
}
