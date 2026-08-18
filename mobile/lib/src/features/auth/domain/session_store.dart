import 'auth_session.dart';

/// Where the session JWT lives between app launches.
///
/// Abstract because the real implementation is platform secure storage (Keychain /
/// Android Keystore, ADR 0007) and a plugin cannot run in a unit test. Every test in
/// this feature substitutes an in-memory store; nothing above `data/` names either.
///
/// `SharedPreferences` is not an acceptable implementation of this interface. It is
/// world-readable on a rooted device and the token is a bearer credential.
abstract interface class SessionStore {
    /// The stored session, or `null` when signed out. Must not throw for "absent" —
    /// a fresh install is the normal case, not a failure.
    Future<AuthSession?> read();

    Future<void> write(AuthSession session);

    /// Idempotent. Called on sign-out and on the terminal 401 of ADR 0007, where it may
    /// run when nothing is stored.
    Future<void> clear();
}
