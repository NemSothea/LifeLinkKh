package kh.lifelink.api.auth.dto;

import java.util.UUID;

/**
 * Matches {@code components/schemas/AuthResponse} in the mobile OpenAPI document, which wins on any
 * conflict with this record.
 *
 * @param token our session JWT. The Google ID token is not reusable anywhere (TM-AUTH-001 S3).
 */
public record AuthResponse(String token, AuthenticatedUser user) {

    /**
     * @param isNewAccount true only on the request that created the account — the client uses it to
     *     route a first-time user into donor setup instead of the home screen
     */
    public record AuthenticatedUser(
            UUID id, String role, String displayName, boolean isNewAccount) {}
}
