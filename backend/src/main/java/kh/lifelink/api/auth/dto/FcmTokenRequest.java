package kh.lifelink.api.auth.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * {@code POST /auth/fcm-token}. The row written is the JWT subject's — there is no user field here,
 * for the same reason there is none on sign-in.
 *
 * <p>An FCM token is a capability: whoever holds it can push notifications to that device. It is
 * never returned by any endpoint and never logged.
 */
public record FcmTokenRequest(@NotBlank String fcmToken) {}
