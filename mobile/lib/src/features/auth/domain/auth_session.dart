import 'auth_user.dart';

/// Our session JWT plus who it belongs to — the whole of what being signed in means.
///
/// The token lives one hour and is never inspected client-side: ADR 0007 makes a 401
/// the only expiry trigger, because reading `exp` here means trusting the device clock
/// and adds a second code path that can disagree with the server's.
final class AuthSession {
    const AuthSession({required this.token, required this.user});

    /// Bearer credential. Anything that can read this can act as the donor, which is
    /// why it is stored in platform secure storage and never logged.
    final String token;

    final AuthUser user;

    @override
    bool operator ==(Object other) =>
        other is AuthSession && other.token == token && other.user == user;

    @override
    int get hashCode => Object.hash(token, user);

    /// The token is redacted on purpose. `toString()` reaches logs and crash reports.
    @override
    String toString() => 'AuthSession(token: <redacted>, user: $user)';
}
