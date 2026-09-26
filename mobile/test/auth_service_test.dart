import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_service.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/facebook_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/google_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/session_store.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';

/// No Firebase, no emulator, no network — which is the point of the abstractions these
/// fakes implement.
void main() {
    late _FakeAuthRepository repository;
    late _InMemorySessionStore store;
    late _FakeGoogleCredentials credentials;
    late _FakeFacebookCredentials facebookCredentials;
    late List<String> events;

    AuthService serviceUnder() => AuthService(
        repository: repository,
        sessionStore: store,
        credentials: credentials,
        facebookCredentials: facebookCredentials,
        clearPushRegistration: () async => events.add('fcm-cleared'),
    );

    setUp(() {
        repository = _FakeAuthRepository();
        store = _InMemorySessionStore();
        credentials = _FakeGoogleCredentials();
        facebookCredentials = _FakeFacebookCredentials();
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

    group('signInWithFacebook (FR-AUTH-004)', () {
        test('stores the session exactly like Google sign-in', () async {
            facebookCredentials.interactiveToken = 'facebook-id-token';

            final result = await serviceUnder().signInWithFacebook();

            expect(result, isA<Success<AuthSession?>>());
            expect((await store.read())?.token, 'jwt-1');
            expect(repository.lastIdToken, 'facebook-id-token');
        });

        test('a dismissed login dialog is Success(null), not a failure', () async {
            facebookCredentials.interactiveToken = null;

            final result = await serviceUnder().signInWithFacebook();

            expect(result, isA<Success<AuthSession?>>());
            expect(result.valueOrNull, isNull);
            expect(store.writes, 0, reason: 'a cancel must not touch stored state');
        });

        test('a platform failure from the Facebook plugin does not escape as an exception',
            () async {
            facebookCredentials.throwOnSignIn = true;

            final result = await serviceUnder().signInWithFacebook();

            expect((result as Failed<AuthSession?>).failure, isA<UnknownFailure>());
        });

        test('does not touch the Google credential source', () async {
            facebookCredentials.interactiveToken = 'facebook-id-token';

            await serviceUnder().signInWithFacebook();

            expect(credentials.signInCalls, 0);
        });
    });

    group('sign-out', () {
        test('clears the push registration before disposing of the token', () async {
            await store.write(_session('jwt-1'));

            await serviceUnder().signOut();

            // Clearing `fcmToken` needs the Firebase user the rules check. Reverse the order
            // and a signed-out phone keeps receiving urgent-request alerts (ADR 0007 §5).
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
                facebookCredentials: facebookCredentials,
                clearPushRegistration: () async => throw Exception('offline'),
            );

            await service.signOut();

            expect(await store.read(), isNull);
            expect(credentials.signedOut, isTrue);
        });
    });

    group('restoreSession (ADR 0009)', () {
        test('returns the stored session when the Firebase user is the one it was written for',
            () async {
            expect(await serviceUnder().restoreSession(), isNull);
            await store.write(_session('jwt-1'));

            expect((await serviceUnder().restoreSession())?.token, 'jwt-1');
            expect(credentials.signedOut, isFalse);
        });

        test('clears a stored session that no Firebase user backs', () async {
            // The gap `firebase/README.md` recorded: Home would open and every read fail.
            await store.write(_session('jwt-1'));
            credentials.uid = null;

            expect(await serviceUnder().restoreSession(), isNull);
            expect(await store.read(), isNull);
        });

        test('clears a session written for a different user, and signs that one out too',
            () async {
            // Also the shape of a session left by the pre-Firebase build, whose id was the
            // backend's UUID rather than a Firebase uid.
            await store.write(_session('jwt-1'));
            credentials.uid = 'someone-else';

            expect(await serviceUnder().restoreSession(), isNull);
            expect(await store.read(), isNull);
            expect(credentials.signedOut, isTrue);
        });

        test('treats a Firebase SDK that cannot answer as no user, not a crash on launch',
            () async {
            await store.write(_session('jwt-1'));
            credentials.throwOnCurrentUid = true;

            expect(await serviceUnder().restoreSession(), isNull);
            expect(await store.read(), isNull);
        });
    });
}

const String _uid = '11111111-1111-1111-1111-111111111111';

AuthSession _session(String token) => AuthSession(
    token: token,
    user: const AuthUser(
        id: _uid,
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

    /// The signed-in Firebase user — [_session]'s id unless a test says otherwise.
    String? uid = _uid;
    bool throwOnSignIn = false;
    bool throwOnCurrentUid = false;
    int signInCalls = 0;
    bool signedOut = false;

    @override
    Future<String?> signIn() async {
        signInCalls++;
        if (throwOnSignIn) throw Exception('platform channel died');
        return interactiveToken;
    }

    @override
    Future<String?> currentUid() async {
        if (throwOnCurrentUid) throw Exception('platform channel died');
        return uid;
    }

    @override
    Future<void> signOut() async => signedOut = true;
}

final class _FakeFacebookCredentials implements FacebookCredentials {
    String? interactiveToken;
    bool throwOnSignIn = false;

    @override
    Future<String?> signIn() async {
        if (throwOnSignIn) throw Exception('platform channel died');
        return interactiveToken;
    }
}
