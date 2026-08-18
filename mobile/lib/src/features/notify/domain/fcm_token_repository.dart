import '../../../core/error/result.dart';

/// This device's push registration, as the app sees it.
///
/// Both calls are authenticated and both run over the intercepted Dio — a 401 here is
/// repairable, unlike one on sign-in.
///
/// Registration is an M3 deliverable even though the push itself is M4 (DEC-002): a
/// request alert at M4 has nowhere to go if no tokens were collected before it.
abstract interface class FcmTokenRepository {
    /// `POST /auth/fcm-token` — register or refresh this device's token.
    ///
    /// Called on sign-in and again on every `onTokenRefresh`, which fires without user
    /// action. A token that is not re-registered after a refresh is a donor who has
    /// silently stopped receiving alerts.
    Future<Result<void>> register(String fcmToken);

    /// `DELETE /auth/fcm-token` — stop pushing to this device.
    ///
    /// Part of sign-out, not an optimisation: a signed-out phone that keeps receiving
    /// urgent-request alerts leaks a patient's need to a stranger and alerts the wrong
    /// donor at the same time (ADR 0007 §5).
    Future<Result<void>> clear();
}
