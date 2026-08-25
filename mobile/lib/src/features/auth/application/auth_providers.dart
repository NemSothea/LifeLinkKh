import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_token_gateway.dart';
import '../../notify/application/push_providers.dart';
import '../data/dio_auth_repository.dart';
import '../data/dio_telegram_auth_repository.dart';
import '../data/firebase_facebook_credentials.dart';
import '../data/firebase_google_credentials.dart';
import '../data/secure_session_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/facebook_credentials.dart';
import '../domain/google_credentials.dart';
import '../domain/session_store.dart';
import '../domain/telegram_auth_repository.dart';
import '../domain/telegram_start_session.dart';
import '../domain/user_role.dart';
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

/// Built on `signInApiClient` — the Dio **without** the auth interceptor. Renewing a
/// session over the client that repairs sessions is the recursion ADR 0007 warns about.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    DioAuthRepository(ref.watch(signInApiClientProvider));

/// Same unintercepted client as `authRepository` — neither Telegram call carries a
/// bearer token either.
@Riverpod(keepAlive: true)
TelegramAuthRepository telegramAuthRepository(TelegramAuthRepositoryRef ref) =>
    DioTelegramAuthRepository(ref.watch(signInApiClientProvider));

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
    facebookCredentials: ref.watch(facebookCredentialsProvider),
    telegramRepository: ref.watch(telegramAuthRepositoryProvider),
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
    Future<void> signIn() => _signInWith(() => ref.read(authServiceProvider).signIn());

    /// Interactive sign-in via Facebook (FR-AUTH-004). Same state machine as [signIn].
    Future<void> signInWithFacebook() =>
        _signInWith(() => ref.read(authServiceProvider).signInWithFacebook());

    /// Stores an already-verified Telegram session (FR-AUTH-004), called by
    /// `TelegramVerifyController` on success only.
    ///
    /// Deliberately **not** routed through `_signInWith`: that helper also puts a
    /// failure onto this controller's state, and `SignInScreen` behind the Telegram
    /// sheet watches this same state for its own error banner. A wrong code or a rate
    /// limit on the sheet's code entry must not flash "sign-in failed" on the screen
    /// behind it — `TelegramVerifyController` owns that failure surface instead.
    Future<void> applyTelegramSession(AuthSession session) async {
        state = AsyncData<AuthSession?>(session);
        await ref.read(pushRegistrationServiceProvider).registerThisDevice();
    }

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
}

/// The Telegram sheet's own state (FR-AUTH-004) — the deep link and session token, not
/// a session. Deliberately **not** `keepAlive`: this is scoped to one sheet's lifetime,
/// and a stale challenge from a closed, reopened sheet must not survive to be reused.
@riverpod
class TelegramStartController extends _$TelegramStartController {
    @override
    FutureOr<TelegramStartSession?> build() => null;

    Future<void> start({UserRole role = UserRole.donor}) async {
        state = const AsyncLoading<TelegramStartSession?>().copyWithPrevious(state);
        final result = await ref.read(authServiceProvider).startTelegramSignIn(role: role);
        state = switch (result) {
            Success(value: final session) => AsyncData<TelegramStartSession?>(session),
            Failed(failure: final failure) => AsyncError<TelegramStartSession?>(
                failure,
                StackTrace.current,
            ),
        };
    }
}

/// The code-entry step's own state (FR-AUTH-004) — separate from
/// `TelegramStartController` because a wrong code should not throw away the deep link
/// already fetched, and separate from `AuthController` for the reason documented on
/// `AuthController.applyTelegramSession`.
@riverpod
class TelegramVerifyController extends _$TelegramVerifyController {
    @override
    FutureOr<void> build() {}

    Future<void> verify({required String sessionToken, required String code}) async {
        state = const AsyncLoading<void>().copyWithPrevious(state);
        final result = await ref
            .read(authServiceProvider)
            .verifyTelegramCode(sessionToken: sessionToken, code: code);
        switch (result) {
            case Success(value: final session):
                // Contractually never null — see `verifyTelegramCode`'s doc comment.
                await ref.read(authControllerProvider.notifier).applyTelegramSession(session!);
                state = const AsyncData<void>(null);
            case Failed(failure: final failure):
                state = AsyncError<void>(failure, StackTrace.current);
        }
    }
}
