import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/data/dio_auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';

/// Covers the wire contract of `POST /auth/google` from
/// `docs/fullstack/api-contract/mobile/contract.md`, and the shapes that break it.
void main() {
    late _StubAdapter adapter;
    late DioAuthRepository repository;

    setUp(() {
        adapter = _StubAdapter();
        repository = DioAuthRepository(
            Dio(BaseOptions(baseUrl: 'http://test.invalid'))..httpClientAdapter = adapter,
        );
    });

    Future<Result<AuthSession>> signIn() =>
        repository.exchangeGoogleToken(idToken: 'google-id-token', role: UserRole.donor);

    test('parses a session and the first-sign-in flag', () async {
        adapter.reply(200, '''
        {"token":"our-jwt","user":{"id":"11111111-1111-1111-1111-111111111111",
         "role":"DONOR","displayName":"Sothea","isNewAccount":true}}
        ''');

        final session = (await signIn() as Success<AuthSession>).value;

        expect(session.token, 'our-jwt');
        expect(session.user.role, UserRole.donor);
        expect(session.user.displayName, 'Sothea');
        // Routes a first-time user into donor setup rather than home.
        expect(session.user.isNewAccount, isTrue);
    });

    test('sends the ID token and the requested role, and nothing else', () async {
        adapter.reply(200, '''
        {"token":"our-jwt","user":{"id":"1","role":"REQUESTER","isNewAccount":false}}
        ''');

        await repository.exchangeGoogleToken(
            idToken: 'google-id-token',
            role: UserRole.requester,
        );

        // No uid, no email, no userId — S1 is visible in the request body, not just in a
        // server check (TM-AUTH-001).
        expect(adapter.lastBody, {'idToken': 'google-id-token', 'role': 'REQUESTER'});
    });

    test('an account with no Google display name still yields a session', () async {
        adapter.reply(200, '''
        {"token":"our-jwt","user":{"id":"1","role":"DONOR","isNewAccount":false}}
        ''');

        final session = (await signIn() as Success<AuthSession>).value;

        expect(session.user.displayName, isEmpty);
    });

    test('a rejected token is an UnauthorizedFailure, not a thrown exception', () async {
        adapter.reply(401, '{"error":{"code":"INVALID_ID_TOKEN","message":"Sign-in failed."}}');

        expect((await signIn() as Failed<AuthSession>).failure, isA<UnauthorizedFailure>());
    });

    test('a rejected role keeps the backend error code for the caller to switch on', () async {
        adapter.reply(
            422,
            '{"error":{"code":"ROLE_NOT_SELF_SERVICE","message":"That role cannot be chosen."}}',
        );

        final failure = (await signIn() as Failed<AuthSession>).failure;

        expect(
            failure,
            isA<ValidationFailure>().having((f) => f.code, 'code', 'ROLE_NOT_SELF_SERVICE'),
        );
    });

    test('the sign-in rate limiter is its own failure, not a generic error', () async {
        adapter.reply(429, '{"error":{"code":"RATE_LIMITED","message":"Too many attempts."}}');

        expect((await signIn() as Failed<AuthSession>).failure, isA<RateLimitedFailure>());
    });

    test('a 200 with no token is an UnknownFailure — never a lost session', () async {
        // A backend bug must not read as "sign in again": that loops the user through a
        // screen that cannot fix anything.
        adapter.reply(200, '{"user":{"id":"1","role":"DONOR"}}');

        expect((await signIn() as Failed<AuthSession>).failure, isA<UnknownFailure>());
    });

    test('an unrecognised role is rejected rather than guessed', () async {
        adapter.reply(200, '{"token":"our-jwt","user":{"id":"1","role":"WIZARD"}}');

        expect((await signIn() as Failed<AuthSession>).failure, isA<UnknownFailure>());
    });

    test('an unreachable backend is a NetworkFailure', () async {
        adapter.failWith(DioExceptionType.connectionError);

        expect((await signIn() as Failed<AuthSession>).failure, isA<NetworkFailure>());
    });

    test('a 500 is a ServerFailure, which is retryable', () async {
        adapter.reply(500, '{"error":{"code":"INTERNAL_ERROR","message":"Something went wrong."}}');

        expect((await signIn() as Failed<AuthSession>).failure, isA<ServerFailure>());
    });

    test('an HTML error page from a proxy degrades to a generic validation code', () async {
        adapter.reply(422, '<html>Gateway rejected</html>', contentType: 'text/html');

        expect(
            (await signIn() as Failed<AuthSession>).failure,
            isA<ValidationFailure>().having((f) => f.code, 'code', 'VALIDATION_FAILED'),
        );
    });
}

final class _StubAdapter implements HttpClientAdapter {
    int _status = 200;
    String _body = '{}';
    String _contentType = Headers.jsonContentType;
    DioExceptionType? _transportFailure;

    Object? lastBody;

    void reply(int status, String body, {String contentType = Headers.jsonContentType}) {
        _status = status;
        _body = body;
        _contentType = contentType;
        _transportFailure = null;
    }

    void failWith(DioExceptionType type) => _transportFailure = type;

    @override
    Future<ResponseBody> fetch(
        RequestOptions options,
        Stream<Uint8List>? requestStream,
        Future<void>? cancelFuture,
    ) async {
        lastBody = options.data;
        final failure = _transportFailure;
        if (failure != null) {
            throw DioException(requestOptions: options, type: failure);
        }
        return ResponseBody.fromString(
            _body,
            _status,
            headers: {
                Headers.contentTypeHeader: [_contentType],
            },
        );
    }

    @override
    void close({bool force = false}) {}
}
