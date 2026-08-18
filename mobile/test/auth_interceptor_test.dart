import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/network/auth_interceptor.dart';
import 'package:lifelink_kh/src/core/network/auth_token_gateway.dart';

/// The four cases ADR 0007 names as owed at the M3 mobile build, plus the two that fall
/// out of them. QA treats the concurrent one as non-negotiable: it is the case that only
/// appears on a cold start over a real network, where three providers fire at once.
void main() {
    late _FakeGateway gateway;
    late _ScriptedAdapter adapter;
    late Dio dio;

    /// Answers 200 only when the bearer token is `fresh`; anything else is a 401. That is
    /// the whole server, and it is enough to distinguish "renewed" from "replayed with the
    /// old token", which is the bug this suite exists to catch.
    Future<ResponseBody> tokenSensitive(RequestOptions options) async {
        final authorized = options.headers['Authorization'] == 'Bearer fresh';
        return ResponseBody.fromString(
            authorized ? '{"ok":true}' : '{"error":{"code":"INVALID_TOKEN"}}',
            authorized ? 200 : 401,
            headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
            },
        );
    }

    setUp(() {
        gateway = _FakeGateway();
        adapter = _ScriptedAdapter(tokenSensitive);
        dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'))
            ..httpClientAdapter = adapter
            ..interceptors.add(
                AuthInterceptor(gateway: gateway, client: () => dio),
            );
    });

    test('attaches the stored token as a bearer credential', () async {
        gateway.token = 'fresh';

        await dio.get<Map<String, dynamic>>('/donors/me');

        expect(adapter.seenAuthorizations, ['Bearer fresh']);
    });

    test('sends no Authorization header when there is no session', () async {
        gateway.token = null;

        await expectLater(
            dio.get<Map<String, dynamic>>('/donors/me'),
            throwsA(isA<DioException>()),
        );
        expect(adapter.seenAuthorizations, [null]);
    });

    test('401 is repaired by one silent renewal and the request is replayed', () async {
        gateway.token = 'stale';
        gateway.renewedToken = 'fresh';

        final response = await dio.get<Map<String, dynamic>>('/donors/me');

        expect(response.statusCode, 200);
        expect(gateway.renewCount, 1);
        // Old token, then the renewed one — proof the replay carried the new credential
        // rather than re-sending the one that was refused.
        expect(adapter.seenAuthorizations, ['Bearer stale', 'Bearer fresh']);
        expect(gateway.abandonCount, 0);
    });

    test('a second 401 after a successful renewal is surfaced, not retried again', () async {
        gateway.token = 'stale';
        // The renewal succeeds and the server still refuses. That is a real failure.
        gateway.renewedToken = 'also-stale';

        await expectLater(
            dio.get<Map<String, dynamic>>('/donors/me'),
            throwsA(
                isA<DioException>().having(
                    (e) => e.response?.statusCode,
                    'statusCode',
                    401,
                ),
            ),
        );
        expect(gateway.renewCount, 1, reason: 'never a renewal loop');
        expect(adapter.requestCount, 2, reason: 'one retry, exactly');
        expect(
            gateway.abandonCount,
            0,
            reason: 'ADR 0007 surfaces this; it does not force a re-login',
        );
    });

    test('concurrent 401s collapse into a single renewal', () async {
        gateway.token = 'stale';
        gateway.renewedToken = 'fresh';
        // Makes the window real: without a delay the first renewal completes before the
        // second request 401s, and the test would pass whether single-flight worked or not.
        gateway.renewDelay = const Duration(milliseconds: 50);

        final responses = await Future.wait([
            dio.get<Map<String, dynamic>>('/donors/me'),
            dio.get<Map<String, dynamic>>('/matches/me'),
            dio.get<Map<String, dynamic>>('/donations/me'),
        ]);

        expect(responses.map((r) => r.statusCode), everyElement(200));
        expect(gateway.renewCount, 1, reason: 'one sign-in on a cold start, not three');
    });

    test('401 on POST /auth/google abandons the session and is never retried', () async {
        gateway.token = null;

        await expectLater(
            dio.post<Map<String, dynamic>>('/auth/google', data: {'idToken': 'x'}),
            throwsA(isA<DioException>()),
        );
        expect(gateway.renewCount, 0, reason: 'the credential itself is gone');
        expect(gateway.abandonCount, 1);
        expect(adapter.requestCount, 1);
    });

    test('a failed renewal abandons the session', () async {
        gateway.token = 'stale';
        // Google access revoked: no ID token can be minted.
        gateway.renewedToken = null;

        await expectLater(
            dio.get<Map<String, dynamic>>('/donors/me'),
            throwsA(isA<DioException>()),
        );
        expect(gateway.renewCount, 1);
        expect(gateway.abandonCount, 1);
        expect(adapter.requestCount, 1, reason: 'nothing to replay without a token');
    });

    test('a renewal that ran once does not block a later 401', () async {
        gateway.token = 'stale';
        gateway.renewedToken = 'fresh';
        await dio.get<Map<String, dynamic>>('/donors/me');

        // Simulates the next hour's expiry: the single-flight latch must have cleared.
        gateway.token = 'stale';
        final response = await dio.get<Map<String, dynamic>>('/donors/me');

        expect(response.statusCode, 200);
        expect(gateway.renewCount, 2);
    });
}

/// Stands in for `AuthService`. Counts calls, because the assertions in this file are
/// mostly about how many times something happened.
final class _FakeGateway implements AuthTokenGateway {
    String? token;
    String? renewedToken;
    Duration renewDelay = Duration.zero;
    int renewCount = 0;
    int abandonCount = 0;

    @override
    Future<String?> currentToken() async => token;

    @override
    Future<String?> renewToken() async {
        renewCount++;
        if (renewDelay > Duration.zero) await Future<void>.delayed(renewDelay);
        token = renewedToken;
        return renewedToken;
    }

    @override
    Future<void> abandonSession() async {
        abandonCount++;
        token = null;
    }
}

/// A Dio adapter that answers from a function instead of a socket, and records what it
/// was asked. No mock package, no local server.
final class _ScriptedAdapter implements HttpClientAdapter {
    _ScriptedAdapter(this._respond);

    final Future<ResponseBody> Function(RequestOptions) _respond;

    final List<String?> seenAuthorizations = [];
    int get requestCount => seenAuthorizations.length;

    @override
    Future<ResponseBody> fetch(
        RequestOptions options,
        Stream<Uint8List>? requestStream,
        Future<void>? cancelFuture,
    ) {
        seenAuthorizations.add(options.headers['Authorization'] as String?);
        return _respond(options);
    }

    @override
    void close({bool force = false}) {}
}
