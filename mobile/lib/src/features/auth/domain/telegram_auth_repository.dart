import '../../../core/error/result.dart';
import 'auth_session.dart';
import 'telegram_start_session.dart';
import 'user_role.dart';

/// The Telegram half of sign-in (FR-AUTH-004, TM-AUTH-002), as the rest of the app sees
/// it. Two calls, not one like `AuthRepository` — Telegram has no client-side token to
/// exchange; the code only exists once the bot has delivered it, so the flow has a real
/// middle step `AuthRepository.exchangeGoogleToken` does not.
///
/// Both `start` and `verify` are called with no bearer token, same reasoning as
/// `POST /auth/google`.
abstract interface class TelegramAuthRepository {
    /// `POST /auth/telegram/start` — mints a challenge and the deep link that opens it.
    ///
    /// [role] is honoured only for a brand-new identity, exactly like
    /// `AuthRepository.exchangeGoogleToken`, and rejected the same way
    /// (`ROLE_NOT_SELF_SERVICE`) for anything else (TM-AUTH-002 E1).
    Future<Result<TelegramStartSession>> start({required UserRole role});

    /// `POST /auth/telegram/verify` — trades the code the bot sent for our session JWT.
    ///
    /// Returns `UnauthorizedFailure` for a wrong or expired code
    /// (`TELEGRAM_CODE_INVALID`) and `ValidationFailure` after too many wrong guesses
    /// (`TOO_MANY_ATTEMPTS`) — never a silent retry of either.
    Future<Result<AuthSession>> verify({required String sessionToken, required String code});
}
