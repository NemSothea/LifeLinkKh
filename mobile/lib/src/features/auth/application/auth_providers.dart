import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/env.dart';
import '../../notify/application/push_providers.dart';
import '../../../core/firebase/firestore_providers.dart';
import '../data/firebase_auth_repository.dart';
import '../data/firebase_facebook_credentials.dart';
import '../data/firebase_google_credentials.dart';
import '../data/secure_session_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/facebook_credentials.dart';
import '../domain/google_credentials.dart';
import '../domain/session_store.dart';
import '../../../core/error/result.dart';
import 'auth_service.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
SessionStore sessionStore(SessionStoreRef ref) => SecureSessionStore();

@Riverpod(keepAlive: true)
GoogleCredentials googleCredentials(GoogleCredentialsRef ref) =>
    FirebaseGoogleCredentials(serverClientId: Env.googleServerClientId);

@Riverpod(keepAlive: true)
FacebookCredentials facebookCredentials(FacebookCredentialsRef ref) =>
    FirebaseFacebookCredentials();

/// Firebase since ADR 0009 phase 4: the Firebase ID token is the session, and the user
/// record is `users/{uid}`.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) => FirebaseAuthRepository(
    ref.watch(firestoreProvider),
    currentUid: ref.watch(currentUidProvider),
    currentDisplayName: ref.watch(currentDisplayNameProvider),
);

/// The service. The push callback is `ref.read` at call time: it is only needed at
/// sign-out, and a callback keeps `AuthService` free of the notify feature's types.
@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) => AuthService(
    repository: ref.watch(authRepositoryProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    credentials: ref.watch(googleCredentialsProvider),
    facebookCredentials: ref.watch(facebookCredentialsProvider),
    clearPushRegistration: () async {
        await ref.read(fcmTokenRepositoryProvider).clear();
    },
);

/// The session, as the UI sees it. `AsyncNotifier` per Week 5 — loading, data, and error
/// are states of one object rather than three booleans.
///
/// `AsyncData(null)` means signed out. That is a real answer, not an empty state: it is
/// what the router redirects on.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
    @override
    Future<AuthSession?> build() => ref.watch(authServiceProvider).restoreSession();

    /// Interactive sign-in from the sign-in screen.
    ///
    /// A dismissed account chooser leaves the state exactly as it was — not an error, and
    /// not a spinner that never resolves.
    Future<void> signIn() => _signInWith(() => ref.read(authServiceProvider).signIn());

    /// Interactive sign-in via Facebook (FR-AUTH-004). Same state machine as [signIn].
    Future<void> signInWithFacebook() =>
        _signInWith(() => ref.read(authServiceProvider).signInWithFacebook());

    Future<void> _signInWith(Future<Result<AuthSession?>> Function() attempt) async {
        state = const AsyncLoading<AuthSession?>().copyWithPrevious(state);
        final result = await attempt();
        switch (result) {
            case Success(value: final session):
                if (session == null) {
                    state = AsyncData<AuthSession?>(state.valueOrNull);
                    return;
                }
                state = AsyncData<AuthSession?>(session);
                // Fire-and-forget: a donor who declined notification permission is signed in
                // and matchable, so this must not block or fail the sign-in.
                await ref.read(pushRegistrationServiceProvider).registerThisDevice();
            case Failed(failure: final failure):
                // The Failure itself is the error object, so the screen can switch on the
                // variant instead of parsing a string.
                state = AsyncError<AuthSession?>(failure, StackTrace.current);
        }
    }

    Future<void> signOut() async {
        state = const AsyncLoading<AuthSession?>().copyWithPrevious(state);
        await ref.read(authServiceProvider).signOut();
        state = const AsyncData<AuthSession?>(null);
    }

    /// The account was deleted (DEC-016) and `AccountDeletionService` has already cleared
    /// the stored session and signed out of Firebase. This only tells the router, which
    /// redirects to sign-in on `AsyncData(null)`.
    ///
    /// Not [signOut]: that clears the push token first, a write to `users/{uid}` — a
    /// document the deletion has just removed.
    void accountDeleted() => state = const AsyncData<AuthSession?>(null);
}
