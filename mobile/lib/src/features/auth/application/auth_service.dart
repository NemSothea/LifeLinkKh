// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/auth_token_gateway.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/facebook_credentials.dart';
import '../domain/google_credentials.dart';
import '../domain/session_store.dart';
import '../domain/telegram_auth_repository.dart';
import '../domain/telegram_start_session.dart';
import '../domain/user_role.dart';

/// The feature's Service (Week 3, S1–S6) and the HTTP layer's [AuthTokenGateway].
///
/// It is one class for both because they are one job: everything that knows how a
/// session is created also knows how it is repaired. Splitting them would put the
/// renewal sequence in a second place that has to stay in step with this one.
///
/// No Flutter import and no Riverpod import (S5) — the providers in this directory are
/// the only Riverpod-aware code. That is what makes the concurrency rule below testable
/// with `flutter test` and no emulator.
final class AuthService implements AuthTokenGateway {
    AuthService({
        required AuthRepository repository,
        required SessionStore sessionStore,
        required GoogleCredentials credentials,
        required FacebookCredentials facebookCredentials,
        required TelegramAuthRepository telegramRepository,
        Future<void> Function()? clearPushRegistration,
        Future<void> Function()? onSessionAbandoned,
    })  : _repository = repository,
          _sessionStore = sessionStore,
          _credentials = credentials,
          _facebookCredentials = facebookCredentials,
          _telegramRepository = telegramRepository,
          _clearPushRegistration = clearPushRegistration,
          _onSessionAbandoned = onSessionAbandoned;

    final AuthRepository _repository;
    final SessionStore _sessionStore;
    final GoogleCredentials _credentials;
    final FacebookCredentials _facebookCredentials;
    final TelegramAuthRepository _telegramRepository;

    /// `DELETE /auth/fcm-token`, injected as a callback rather than as a repository.
    ///
    /// The FCM repository runs over the intercepted Dio, and that interceptor holds this
    /// object — taking the repository in the constructor would be a construction cycle.
    /// A callback resolved at call time is not.
    final Future<void> Function()? _clearPushRegistration;

    /// Fired when a session is beyond repair, so the app can route to sign-in. The
    /// service does not navigate; it reports.
    final Future<void> Function()? _onSessionAbandoned;

    /// Interactive sign-in, for the sign-in screen.
    ///
    /// `Success(null)` means the user dismissed the Google account chooser. A cancel is
    /// not a failure and must not render as an error — that distinction is why the
    /// success type is nullable rather than the whole call returning a `Failure`.
    Future<Result<AuthSession?>> signIn({UserRole role = UserRole.donor}) =>
        _signInWith(_credentials.signIn, role: role, failureMessage: 'Google sign-in failed');

    /// Interactive sign-in via Facebook, for the sign-in screen's second button
    /// (FR-AUTH-004). Same contract as [signIn] — `Success(null)` means the user
    /// dismissed the Facebook login dialog.
    Future<Result<AuthSession?>> signInWithFacebook({UserRole role = UserRole.donor}) =>
        _signInWith(
            _facebookCredentials.signIn,
            role: role,
            failureMessage: 'Facebook sign-in failed',
        );

    /// Shared by [signIn] and [signInWithFacebook]: both exchange a Firebase ID token
    /// for our session JWT through the same `POST /auth/google` call — the backend
    /// verifies a Firebase-issued token regardless of which federated provider minted
    /// it (FR-AUTH-004 scope).
    Future<Result<AuthSession?>> _signInWith(
        Future<String?> Function() obtainIdToken, {
        required UserRole role,
        required String failureMessage,
    }) async {
        assert(
            UserRole.selfService.contains(role),
            'only DONOR and REQUESTER may be requested at sign-up; the server answers '
            '422 ROLE_NOT_SELF_SERVICE for anything else (TM-AUTH-001 E1)',
        );

        final String? idToken;
        try {
            idToken = await obtainIdToken();
        } on Object catch (_) {
            // A platform-channel failure from the Google/Facebook/Firebase plugin. Not a
            // domain failure and not something a message from us can explain.
            return Failed(UnknownFailure(message: failureMessage));
        }
        if (idToken == null) return const Success(null);

        final result = await _repository.exchangeGoogleToken(
            idToken: idToken,
            role: role,
        );
        return switch (result) {
            Success(value: final session) => await _store(session),
            Failed(failure: final failure) => Failed(failure),
        };
    }

    /// Starts a Telegram sign-in (FR-AUTH-004): mints a challenge and the deep link the
    /// UI opens next. Not part of `_signInWith` — there is no ID token yet, only an
    /// invitation to go get the code from the bot.
    Future<Result<TelegramStartSession>> startTelegramSignIn({UserRole role = UserRole.donor}) {
        assert(
            UserRole.selfService.contains(role),
            'only DONOR and REQUESTER may be requested at sign-up; the server answers '
            '422 ROLE_NOT_SELF_SERVICE for anything else (TM-AUTH-002 E1)',
        );
        return _telegramRepository.start(role: role);
    }

    /// Completes a Telegram sign-in with the code the bot sent. Unlike [signIn] and
    /// [signInWithFacebook] there is no ID token exchange — `verify` mints the session
    /// JWT directly — but the result still lands through [_store] so a Telegram session
    /// persists and routes exactly like every other provider's.
    ///
    /// `Failed`, never `Success(null)`: unlike an account chooser or a login dialog, a
    /// blank or wrong code the donor submits is a real failure to show, not a cancel.
    Future<Result<AuthSession?>> verifyTelegramCode({
        required String sessionToken,
        required String code,
    }) async {
        final result = await _telegramRepository.verify(sessionToken: sessionToken, code: code);
        return switch (result) {
            Success(value: final session) => await _store(session),
            Failed(failure: final failure) => Failed(failure),
        };
    }

    /// The stored session, if this install has one. Called at startup.
    ///
    /// A `null` here is not "signed out for good": ADR 0007 has the app silently
    /// re-authenticate through the Firebase SDK's own stored credential, so the donor who
    /// opens a 03:00 push alert does not meet a login screen.
    Future<AuthSession?> restoreSession() => _sessionStore.read();

    /// Signs out of everything, in the order that matters.
    ///
    /// Push registration is cleared **first**, while the JWT that authorises the call
    /// still exists. Disposing of the token first would leave the device registered for
    /// urgent-request alerts with no way left to unregister it.
    Future<void> signOut() async {
        try {
            await _clearPushRegistration?.call();
        } on Object catch (_) {
            // Deliberately swallowed. A user who asked to sign out is signed out even if
            // the network is down; the stale token's cost is bounded by the same one-hour
            // window as the JWT.
        }
        await _sessionStore.clear();
        await _credentials.signOut();
    }

    @override
    Future<String?> currentToken() async => (await _sessionStore.read())?.token;

    @override
    Future<String?> renewToken() async {
        // Only Google/Facebook sessions can renew silently — both rest on a Firebase
        // session `_credentials.idToken` can refresh. A Telegram session has none: this
        // returns null for it below, same as revoked Google access, and ADR 0007 sends
        // the donor to sign in again rather than re-running the bot round-trip silently.
        //
        // forceRefresh: the cached Google ID token is presumed stale — a 401 is what got
        // us here.
        final String? idToken;
        try {
            idToken = await _credentials.idToken(forceRefresh: true);
        } on Object catch (_) {
            return null;
        }
        // No Firebase user, or Google access revoked. Terminal.
        if (idToken == null) return null;

        // The role is ignored for a returning user, which every renewal is by definition.
        final result = await _repository.exchangeGoogleToken(
            idToken: idToken,
            role: UserRole.donor,
        );
        return switch (result) {
            Success(value: final session) => (await _store(session)).valueOrNull?.token,
            Failed() => null,
        };
    }

    @override
    Future<void> abandonSession() async {
        await _sessionStore.clear();
        // Firebase is signed out too, so the sign-in screen offers the account chooser
        // rather than silently retrying a credential that has already been refused.
        await _credentials.signOut();
        await _onSessionAbandoned?.call();
    }

    Future<Result<AuthSession?>> _store(AuthSession session) async {
        await _sessionStore.write(session);
        return Success(session);
    }
}
