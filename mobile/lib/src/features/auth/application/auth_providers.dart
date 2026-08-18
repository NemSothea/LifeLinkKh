import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_token_gateway.dart';
import '../../notify/application/push_providers.dart';
import '../data/dio_auth_repository.dart';
import '../data/firebase_google_credentials.dart';
import '../data/secure_session_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
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

/// Built on `signInApiClient` — the Dio **without** the auth interceptor. Renewing a
/// session over the client that repairs sessions is the recursion ADR 0007 warns about.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    DioAuthRepository(ref.watch(signInApiClientProvider));

/// The service, and the [AuthTokenGateway] the HTTP layer holds.
///
/// The two callbacks are `ref.read` at call time on purpose. `fcmTokenRepository` needs
/// the intercepted Dio, which needs this object — reading it eagerly here would be a
/// provider cycle; reading it when sign-out actually happens is not.
@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) => AuthService(
    repository: ref.watch(authRepositoryProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    credentials: ref.watch(googleCredentialsProvider),
    clearPushRegistration: () async {
        await ref.read(fcmTokenRepositoryProvider).clear();
    },
    onSessionAbandoned: () async {
        // Drops the cached session so the router's redirect sends the user to sign-in.
        // The service reports; routing is decided here.
        ref.invalidate(authControllerProvider);
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
    Future<void> signIn() async {
        state = const AsyncLoading<AuthSession?>().copyWithPrevious(state);
        final result = await ref.read(authServiceProvider).signIn();
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
}
