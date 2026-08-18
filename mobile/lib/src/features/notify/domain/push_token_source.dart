/// This device's FCM registration token, behind an interface.
///
/// Abstract for the same reason as the auth plugins: `firebase_messaging` needs a
/// platform channel, and the registration sequence has to be testable without one.
abstract interface class PushTokenSource {
    /// Asks the OS for notification permission.
    ///
    /// Returns false when the user declines. A declined donor is still a donor — they
    /// keep a working app and simply do not get alerts, so this must never gate sign-in.
    Future<bool> requestPermission();

    /// The current FCM token, or `null` when permission was declined or Play Services is
    /// unavailable (which is common on Chinese-market Android in Phnom Penh).
    Future<String?> currentToken();

    /// Fires when FCM rotates the token — on reinstall, restore, or its own schedule, with
    /// no user action. A rotation that is not re-registered is a donor who has silently
    /// stopped receiving urgent-request alerts.
    Stream<String> tokenRefreshes();
}
