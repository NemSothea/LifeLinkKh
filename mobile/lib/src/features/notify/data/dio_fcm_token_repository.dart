import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/fcm_token_repository.dart';

/// Talks to the two `/auth/fcm-token` endpoints over the intercepted Dio.
///
/// The server takes the user from the JWT, never from the body — the request carries the
/// token and nothing else. There is no `userId` field to send, which is `TM-AUTH-001`
/// S1 expressed as an absent parameter.
final class DioFcmTokenRepository implements FcmTokenRepository {
    const DioFcmTokenRepository(this._dio);

    final Dio _dio;

    static const String path = '/auth/fcm-token';

    @override
    Future<Result<void>> register(String fcmToken) async {
        try {
            await _dio.post<void>(path, data: {'fcmToken': fcmToken});
            return const Success(null);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        }
    }

    @override
    Future<Result<void>> clear() async {
        try {
            await _dio.delete<void>(path);
            return const Success(null);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        }
    }
}
