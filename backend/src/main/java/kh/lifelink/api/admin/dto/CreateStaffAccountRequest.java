package kh.lifelink.api.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * {@code POST /admin/staff/accounts} — create a portal account outright, username and password.
 *
 * <p>The sibling of {@code AssignStaffRoleRequest}, for the case that one cannot serve. Promotion
 * requires an existing self-service account, because it turns a verified Google identity into a
 * staff one. But a hospital clerk who will only ever use a desktop browser has no mobile account to
 * promote, and until this endpoint existed the only way to give them one was a Flyway migration
 * written by a developer — which is not a workable way to hire someone.
 *
 * <p>Creating an identity here does not reopen {@code TM-AUTH-001} S1. That rule protects
 * <em>self-service</em> sign-up: nobody may claim to be someone by typing their name. This path is
 * an authenticated ADMIN deliberately provisioning an account they are accountable for, which is
 * the same trust the promote endpoint already carries.
 *
 * @param username lowercase letters, digits, dot, dash and underscore. Constrained because it is
 *     typed at a sign-in box by someone reading it off a note — mixed case and spaces produce
 *     "wrong username or password" with no visible cause.
 * @param password minimum eight characters. Not a policy engine: a length floor is the one rule
 *     that measurably helps, and the rest (rotation, complexity classes) produces `Password1!`
 *     everywhere it is enforced.
 * @param role HOSPITAL or ADMIN, checked against the same rules as promotion.
 * @param hospitalId required for HOSPITAL, must be absent for ADMIN.
 */
public record CreateStaffAccountRequest(
        @NotBlank @Size(min = 3, max = 64) @Pattern(regexp = "[a-z0-9._-]+") String username,
        @NotBlank @Size(min = 8, max = 200) String password,
        @NotBlank String displayName,
        @NotBlank String role,
        UUID hospitalId) {}
