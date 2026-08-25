import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';

/// Parses `AuthResponse` from the mobile OpenAPI document — `POST /auth/google` and
/// `POST /auth/telegram/verify` both answer this exact shape, so both repositories
/// share this rather than each keeping its own copy to drift out of step.
///
/// Throws [FormatException] on a shape mismatch rather than filling in defaults: a
/// session with a guessed role is worse than no session.
AuthSession authSessionFromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty || user is! Map) {
        throw const FormatException('sign-in response has no token');
    }
    final id = user['id'];
    final role = UserRole.fromWire(user['role'] as String?);
    if (id is! String || role == null) {
        throw const FormatException('sign-in response has no usable user');
    }
    return AuthSession(
        token: token,
        user: AuthUser(
            id: id,
            role: role,
            // A missing display name is valid; an absent field is not a reason to reject
            // an otherwise working session.
            displayName: user['displayName'] as String? ?? '',
            isNewAccount: user['isNewAccount'] as bool? ?? false,
        ),
    );
}
