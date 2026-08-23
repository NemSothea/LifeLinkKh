package kh.lifelink.api.admin;

import jakarta.validation.Valid;
import java.util.List;
import kh.lifelink.api.admin.dto.AdminUserResponse;
import kh.lifelink.api.admin.dto.AssignStaffRoleRequest;
import kh.lifelink.api.admin.dto.StaffResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Staff account management (TM-AUTH-001 E1). {@code SecurityConfig} restricts every
 * {@code /admin/**} path to {@code ADMIN} — a {@code HOSPITAL}, {@code DONOR} or {@code REQUESTER}
 * JWT reaching here gets a 403 before this class ever runs, same shape as {@code PortalController}.
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

    @PostMapping("/staff")
    StaffResponse assignStaffRole(@Valid @RequestBody AssignStaffRoleRequest body) {
        return admin.assignStaffRole(body);
    }
}
