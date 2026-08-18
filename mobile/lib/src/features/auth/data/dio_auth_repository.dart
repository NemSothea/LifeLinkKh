import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';

/// The only class in this feature that knows Dio exists, and the only place a wire
/// field name appears as a string.
///
/// Constructed with the **unintercepted** Dio. Sign-in carries no bearer token, and
/// running it through the auth interceptor would make session renewal depend on the
/// session being renewed.
///
/// It maps `DioException` to [Failure] here, at the data boundary, because that is the
/// layer that owns the transport (Week 6). Everything above receives a [Result].
final class DioAuthRepository implements AuthRepository {
    const DioAuthRepository(this._dio);

    final Dio _dio;

    /// `POST /auth/google` is the one path the auth interceptor must never retry or
    /// decorate — the constant is shared with it so the two cannot drift apart.
    static const String signInPath = '/auth/google';

    @override
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    }) async {
        try {
            final response = await _dio.post<Map<String, dynamic>>(
                signInPath,
                data: {'idToken': idToken, 'role': role.wireValue},
            );
            final body = response.data;
            if (body == null) {
                return const Failed(UnknownFailure(message: 'empty sign-in response'));
            }
            return Success(_sessionFromJson(body));
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            // A 200 whose shape we do not recognise. Never an UnauthorizedFailure — that
            // would send the user to sign in again over a backend bug.
            return Failed(UnknownFailure(message: error.message));
        }
    }

    /// Parses `AuthResponse` from the mobile OpenAPI document. Throws [FormatException]
    /// on a shape mismatch rather than filling in defaults: a session with a guessed
    /// role is worse than no session.
    AuthSession _sessionFromJson(Map<String, dynamic> json) {
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
                // A Google account with no display name is valid; an absent field is not
                // a reason to reject a working session.
                displayName: user['displayName'] as String? ?? '',
                isNewAccount: user['isNewAccount'] as bool? ?? false,
            ),
        );
    }
}
