package kh.lifelink.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * {@code POST /auth/portal/login}. Portal staff only — donors and requesters authenticate through
 * Google or Telegram (ADR 0002) and never hold a username.
 *
 * <p>Neither field is echoed anywhere: not in the response, not in a log line, not in a validation
 * message. The size caps exist to stop a multi-megabyte body reaching BCrypt, which is deliberately
 * slow by design and would otherwise be a free way to burn server CPU.
 */
public record PortalLoginRequest(
        @NotBlank @Size(max = 64) String username, @NotBlank @Size(max = 200) String password) {}
