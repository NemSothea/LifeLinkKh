import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/auth_session.dart';
import '../domain/telegram_auth_repository.dart';
import '../domain/telegram_start_session.dart';
import '../domain/user_role.dart';
import 'auth_session_json.dart';

/// Constructed with the **unintercepted** Dio, same reasoning as `DioAuthRepository`:
/// neither call carries a bearer token, so neither should risk the auth interceptor's
/// retry-on-401 path.
final class DioTelegramAuthRepository implements TelegramAuthRepository {
    const DioTelegramAuthRepository(this._dio);

    final Dio _dio;

    static const String _startPath = '/auth/telegram/start';
    static const String _verifyPath = '/auth/telegram/verify';

    @override
    Future<Result<TelegramStartSession>> start({required UserRole role}) async {
        try {
            final response = await _dio.post<Map<String, dynamic>>(
                _startPath,
                data: {'role': role.wireValue},
            );
            final body = response.data;
            final sessionToken = body?['sessionToken'];
            final deepLink = body?['deepLink'];
            if (sessionToken is! String || deepLink is! String) {
                return const Failed(UnknownFailure(message: 'empty telegram start response'));
            }
            return Success(
                TelegramStartSession(sessionToken: sessionToken, deepLink: deepLink),
            );
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        }
    }

    @override
    Future<Result<AuthSession>> verify({
        required String sessionToken,
        required String code,
    }) async {
        try {
            final response = await _dio.post<Map<String, dynamic>>(
                _verifyPath,
                data: {'sessionToken': sessionToken, 'code': code},
            );
            final body = response.data;
            if (body == null) {
                return const Failed(UnknownFailure(message: 'empty telegram verify response'));
            }
            return Success(authSessionFromJson(body));
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }
}
