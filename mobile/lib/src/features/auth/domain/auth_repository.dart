import '../../../core/error/result.dart';
import 'auth_session.dart';
import 'user_role.dart';

/// The token exchange, as the rest of the app sees it (Week 3 rule S4).
///
/// One method, on purpose. `POST /auth/google` is the only endpoint in the app that
/// takes no bearer token, so it is the only one that can be called over a Dio without
/// the auth interceptor — and it must be, or renewing a session would require the
/// session it is renewing. FCM token registration is an authenticated call and lives in
/// the NOTIFY feature for that reason.
abstract interface class AuthRepository {
    /// `POST /auth/google` — trades a Google ID token for our session JWT, creating the
    /// account on first sign-in.
    ///
    /// [role] is honoured only for a brand-new identity and ignored for a returning
    /// user; the server decides which case this is. Passing a non-self-service role
    /// yields a `ValidationFailure` with code `ROLE_NOT_SELF_SERVICE` — never a silent
    /// downgrade (`TM-AUTH-001` E1).
    ///
    /// Returns a [Result] and does not throw for anything a user can cause, including
    /// a rejected token (`UnauthorizedFailure`) and a rate limit
    /// (`RateLimitedFailure`).
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    });
}
