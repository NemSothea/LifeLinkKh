import 'package:dio/dio.dart';

import 'failure.dart';

/// Translates transport errors into domain [Failure]s.
///
/// Lives in `core/` rather than in one feature's `data/` because every repository in
/// the app talks to the same API over the same Dio and would otherwise write this
/// switch again. The layer rule still holds: only `data/` code calls it.
///
/// The status code decides the variant, never the message. The backend's
/// `ErrorResponse` is `{"error": {"code": "...", "message": "..."}}` and its prose is
/// explicitly not a stable contract — only `code` is.
Failure failureFromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
        final code = _errorCode(error.response?.data);
        return switch (status) {
            401 => const UnauthorizedFailure(),
            403 => ForbiddenFailure(code: code ?? 'FORBIDDEN'),
            404 => const NotFoundFailure(),
            409 => ConflictFailure(code: code ?? 'CONFLICT'),
            429 => const RateLimitedFailure(),
            400 || 422 => ValidationFailure(code: code ?? 'VALIDATION_FAILED'),
            >= 500 => const ServerFailure(),
            _ => UnknownFailure(message: 'unexpected status $status'),
        };
    }

    return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => const NetworkFailure(),
        DioExceptionType.cancel => const UnknownFailure(message: 'request cancelled'),
        _ => UnknownFailure(message: error.message ?? 'transport failure'),
    };
}

/// Reads `error.code` out of the backend's error envelope.
///
/// Returns `null` rather than throwing when the body is not that shape — a proxy or a
/// container that answers with HTML must degrade to the generic code, not to a crash
/// inside the error path.
String? _errorCode(Object? body) {
    if (body is! Map) return null;
    final envelope = body['error'];
    if (envelope is! Map) return null;
    final code = envelope['code'];
    return code is String ? code : null;
}
