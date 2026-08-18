import 'user_role.dart';

/// The signed-in user as the app knows them.
///
/// Deliberately thin: no email, no phone, no Firebase uid. The client never needs the
/// uid — identity travels in the JWT's `sub` and the server reads it from the verified
/// token and nowhere else (`TM-AUTH-001` S1). Storing it here would invite a future
/// screen to send it.
final class AuthUser {
    const AuthUser({
        required this.id,
        required this.role,
        required this.displayName,
        required this.isNewAccount,
    });

    /// Our own user id (UUID), not the Firebase uid.
    final String id;

    final UserRole role;

    /// From the Google profile. May be empty — a Google account without a name is
    /// valid, and an empty string is not an error state.
    final String displayName;

    /// True only on the response that created the account. Routes a first-time donor
    /// into profile setup instead of home. Not persisted as a fact about the user —
    /// it is a fact about that one response.
    final bool isNewAccount;

    @override
    bool operator ==(Object other) =>
        other is AuthUser &&
        other.id == id &&
        other.role == role &&
        other.displayName == displayName &&
        other.isNewAccount == isNewAccount;

    @override
    int get hashCode => Object.hash(id, role, displayName, isNewAccount);

    @override
    String toString() => 'AuthUser($id, ${role.wireValue}, new: $isNewAccount)';
}
