import '../../../core/error/result.dart';
import 'account_deletion.dart';

/// Deleting the signed-in user's own account (DEC-016), as the rest of the app sees it.
///
/// A Function rather than Firestore writes: deletion closes requests and withdraws
/// acceptances on documents other people read, which the Security Rules rightly refuse a
/// client. Behind an interface so the whole flow — re-authentication, the retry, the
/// sign-out after — is testable without a Firebase project.
abstract interface class AccountRepository {
    /// `ForbiddenFailure.code` when the ID token's `auth_time` is more than five minutes
    /// old. The service re-authenticates once and retries on exactly this code.
    static const String recentSignInRequired = 'RECENT_SIGN_IN_REQUIRED';

    /// `ForbiddenFailure.code` for an admin account. Admins are portal-only (DEC-014) and
    /// removed by an operator, so from this app it is practically unreachable.
    static const String adminAccount = 'ADMIN_ACCOUNT';

    /// Deletes the caller's account — no argument, because the Function only ever deletes
    /// the uid it verified from the token.
    ///
    /// Returns a [Result] and does not throw for anything a user can cause: no network is
    /// `NetworkFailure`, a stale sign-in is `ForbiddenFailure(code: recentSignInRequired)`.
    Future<Result<AccountDeletion>> deleteAccount();
}
