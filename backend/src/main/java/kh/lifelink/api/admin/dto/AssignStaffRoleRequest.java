package kh.lifelink.api.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * @param userId must be an existing DONOR/REQUESTER account — this promotes a row, it never creates
 *     one (TM-AUTH-001 S1: identity comes only from a verified Google sign-in).
 * @param role HOSPITAL or ADMIN. Anything else is refused, never silently coerced.
 * @param hospitalId required for HOSPITAL, must be absent for ADMIN — an admin is not scoped to one
 *     hospital.
 */
public record AssignStaffRoleRequest(
        @NotNull UUID userId, @NotBlank String role, UUID hospitalId) {}
