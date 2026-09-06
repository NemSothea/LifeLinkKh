package kh.lifelink.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * {@code POST /auth/portal/password} — a staff member changing their own password.
 *
 * <p>{@code currentPassword} is required even though the caller already holds a valid session. A
 * session proves possession of a browser, not of the password: without this check, a laptop left
 * unlocked for one minute is enough to lock its owner out of their own account permanently, since
 * this product has no password reset.
 */
public record ChangePasswordRequest(
        @NotBlank String currentPassword, @NotBlank @Size(min = 8, max = 200) String newPassword) {}
