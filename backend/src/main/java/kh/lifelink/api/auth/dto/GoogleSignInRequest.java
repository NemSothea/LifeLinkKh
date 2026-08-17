package kh.lifelink.api.auth.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * The whole of what {@code POST /auth/google} accepts.
 *
 * <p>Note what is absent: there is no {@code userId}, {@code firebaseUid}, {@code uid} or {@code
 * email} field. That is the S1 control expressed structurally — a future controller cannot start
 * trusting a client-supplied identity, because there is nothing to bind it to.
 *
 * @param idToken the Google ID token from the Firebase SDK
 * @param role honoured only when this identity has no account yet; ignored entirely for a returning
 *     user. Validated against the allow-list in the service, not here, so the rejection can be a
 *     422 with its own code rather than a generic binding failure (E1).
 */
public record GoogleSignInRequest(@NotBlank String idToken, String role) {}
