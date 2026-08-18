import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_service.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/google_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/session_store.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';

/// No Firebase, no emulator, no network — which is the point of the abstractions these
/// fakes implement. The Firebase project does not exist yet (`docs/scope.md`).
void main() {
    late _FakeAuthRepository repository;
    late _InMemorySessionStore store;
    late _FakeGoogleCredentials credentials;
    late List<String> events;

    AuthService serviceUnder() => AuthService(
        repository: repository,
        sessionStore: store,
        credentials: credentials,
        clearPushRegistration: () async => events.add('fcm-cleared'),
        onSessionAbandoned: () async => events.add('abandoned'),
    );

    setUp(() {
        repository = _FakeAuthRepository();
        store = _InMemorySessionStore();
        credentials = _FakeGoogleCredentials();
        events = [];
    });

    group('signIn', () {
        test('stores the session so it survives a restart', () async {
            credentials.interactiveToken = 'google-id-token';

            final result = await serviceUnder().signIn();

            expect(result, isA<Success<AuthSession?>>());
            expect((await store.read())?.token, 'jwt-1');
            expect(repository.lastIdToken, 'google-id-token');
        });

        test('requests the DONOR role by default, and it reaches the server', () async {
            credentials.interactiveToken = 'google-id-token';

            await serviceUnder().signIn();

            expect(repository.lastRole, UserRole.donor);
        });

        test('a dismissed account chooser is Success(null), not a failure', () async {
            credentials.interactiveToken = null;

            final result = await serviceUnder().signIn();

            expect(result, isA<Success<AuthSession?>>());
            expect(result.valueOrNull, isNull);
            expect(store.writes, 0, reason: 'a cancel must not touch stored state');
        });

        test('a rejected role surfaces the server code and stores nothing', () async {
            credentials.interactiveToken = 'google-id-token';
            repository.failure = const ValidationFailure(code: 'ROLE_NOT_SELF_SERVICE');

            final result = await serviceUnder().signIn();

            expect(
                (result as Failed<AuthSession?>).failure,
                isA<ValidationFailure>().having(
                    (f) => f.code,
                    'code',
                    'ROLE_NOT_SELF_SERVICE',
                ),
            );
            expect(await store.read(), isNull);
        });

        test('a platform failure from the Google plugin does not escape as an exception', () async {
            credentials.throwOnSignIn = true;

            final result = await serviceUnder().signIn();

            expect((result as Failed<AuthSession?>).failure, isA<UnknownFailure>());
        });
    });

    group('renewToken (ADR 0007)', () {
        test('forces a fresh Google ID token rather than reusing the cached one', () async {
            await store.write(_session('jwt-old'));
            credentials.silentToken = 'refreshed-google-token';

            final token = await serviceUnder().renewToken();

            expect(token, 'jwt-1');
            expect(credentials.forceRefreshRequested, isTrue);
            expect((await store.read())?.token, 'jwt-1');
        });

        test('returns null when Google access is gone, leaving the caller to give up', () async {
            await store.write(_session('jwt-old'));
            credentials.silentToken = null;

            expect(await serviceUnder().renewToken(), isNull);
        });

        test('returns null when the exchange itself is refused', () async {
            await store.write(_session('jwt-old'));
            credentials.silentToken = 'refreshed-google-token';
            repository.failure = const UnauthorizedFailure();

            expect(await serviceUnder().renewToken(), isNull);
        });
    });

    group('sign-out', () {
        test('clears the push registration before disposing of the token', () async {
            await store.write(_session('jwt-1'));

            await serviceUnder().signOut();

            // The DELETE is authenticated by the JWT being discarded. Reverse the order and
            // a signed-out phone keeps receiving urgent-request alerts (ADR 0007 §5).
            expect(events, ['fcm-cleared']);
            expect(await store.read(), isNull);
            expect(credentials.signedOut, isTrue);
        });

        test('signs out anyway when clearing the push token fails', () async {
            await store.write(_session('jwt-1'));
            final service = AuthService(
                repository: repository,
                sessionStore: store,
                credentials: credentials,
                clearPushRegistration: () async => throw Exception('offline'),
            );

            await service.signOut();

            expect(await store.read(), isNull);
            expect(credentials.signedOut, isTrue);
        });

        test('abandonSession clears both sessions and reports it once', () async {
            await store.write(_session('jwt-1'));

            await serviceUnder().abandonSession();

            expect(await store.read(), isNull);
            expect(credentials.signedOut, isTrue);
            expect(events, ['abandoned']);
        });
    });

    test('restoreSession returns what was stored', () async {
        expect(await serviceUnder().restoreSession(), isNull);
        await store.write(_session('jwt-1'));
        expect((await serviceUnder().restoreSession())?.token, 'jwt-1');
    });

    test('currentToken reads through to the store on every call', () async {
        final service = serviceUnder();
        expect(await service.currentToken(), isNull);
        await store.write(_session('jwt-1'));
        // Not cached: the interceptor asks before every request, and a renewal that
        // happened on another request must be visible immediately.
        expect(await service.currentToken(), 'jwt-1');
    });
}

AuthSession _session(String token) => AuthSession(
    token: token,
    user: const AuthUser(
        id: '11111111-1111-1111-1111-111111111111',
        role: UserRole.donor,
        displayName: 'Sothea',
        isNewAccount: false,
    ),
);

final class _FakeAuthRepository implements AuthRepository {
    Failure? failure;
    String? lastIdToken;
    UserRole? lastRole;

    @override
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    }) async {
        lastIdToken = idToken;
        lastRole = role;
        final failure = this.failure;
        if (failure != null) return Failed(failure);
        return Success(_session('jwt-1'));
    }
}

final class _InMemorySessionStore implements SessionStore {
    AuthSession? _session;
    int writes = 0;

    @override
    Future<AuthSession?> read() async => _session;

    @override
    Future<void> write(AuthSession session) async {
        writes++;
        _session = session;
    }

    @override
    Future<void> clear() async => _session = null;
}

final class _FakeGoogleCredentials implements GoogleCredentials {
    String? interactiveToken;
    String? silentToken;
    bool throwOnSignIn = false;
    bool forceRefreshRequested = false;
    bool signedOut = false;

    @override
    Future<String?> signIn() async {
        if (throwOnSignIn) throw Exception('platform channel died');
        return interactiveToken;
    }

    @override
    Future<String?> idToken({bool forceRefresh = false}) async {
        forceRefreshRequested = forceRefresh;
        return silentToken;
    }

    @override
    Future<void> signOut() async => signedOut = true;
}
