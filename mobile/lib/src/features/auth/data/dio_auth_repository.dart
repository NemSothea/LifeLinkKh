import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/user_role.dart';
import 'auth_session_json.dart';

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
            return Success(authSessionFromJson(body));
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            // A 200 whose shape we do not recognise. Never an UnauthorizedFailure — that
            // would send the user to sign in again over a backend bug.
            return Failed(UnknownFailure(message: error.message));
        }
    }
}
