package kh.lifelink.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * {@code POST /auth/fcm-token}. The row written is the JWT subject's — there is no user field here,
 * for the same reason there is none on sign-in.
 *
 * <p>An FCM token is a capability: whoever holds it can push notifications to that device. It is
 * never returned by any endpoint and never logged.
 *
 * <p>{@code language} rides along because it answers the other half of the same question. {@code
 * users.language} decides which language {@code RequestAlertNotifier} sends an urgent-request alert
 * in, and until now nothing on any client ever wrote it — every row kept the {@code 'km'} default
 * from {@code V1__init.sql}, so a donor who set the app to English still got a Khmer alert for the
 * one message in this product that has to be understood immediately. Optional: a client that omits
 * it leaves the stored value alone rather than resetting it.
 */
public record FcmTokenRequest(
        @NotBlank String fcmToken, @Pattern(regexp = "km|en") String language) {}
