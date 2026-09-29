// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../auth/domain/facebook_credentials.dart';
import '../../auth/domain/google_credentials.dart';
import '../../auth/domain/reauthentication.dart';
import '../../auth/domain/session_store.dart';
import '../domain/account_deletion.dart';
import '../domain/account_repository.dart';

/// Deleting the signed-in user's account, in the order that matters (DEC-016).
///
/// No Flutter import and no Riverpod import, like `AuthService`: the ordering below is the
/// whole feature, and it is tested with fakes and no emulator.
///
/// 1. **Re-authenticate first**, with whichever provider this Firebase user came from. The
///    Function refuses a sign-in older than five minutes; asking before the call rather
///    than after the first refusal means one dialog in the normal case, not two.
/// 2. **Call the Function.** If it still says the sign-in is too old (the dialog answered
///    from a cache, or the clock is off), re-authenticate once more and retry once. A
///    second refusal is shown, not looped on.
/// 3. **Only then end the session locally.** A failure anywhere before this leaves the
///    stored session and the Firebase user exactly as they were — the account still
///    exists, and the user must still be signed in to it.
final class AccountDeletionService {
    AccountDeletionService({
        required AccountRepository repository,
        required SessionStore sessionStore,
        required GoogleCredentials credentials,
        required FacebookCredentials facebookCredentials,
        Future<void> Function()? clearLocalData,
    })  : _repository = repository,
          _sessionStore = sessionStore,
          _credentials = credentials,
          _facebookCredentials = facebookCredentials,
          _clearLocalData = clearLocalData;

    final AccountRepository _repository;
    final SessionStore _sessionStore;
    final GoogleCredentials _credentials;
    final FacebookCredentials _facebookCredentials;

    /// The same `LocalDataEraser` sign-out runs (SEC-REVIEW-003 F-07): Drift tables,
    /// Firestore offline cache, FCM token. A deleted account's cached answers and
    /// requester phone numbers must not outlive it on the phone.
    final Future<void> Function()? _clearLocalData;

    /// `ForbiddenFailure.code` for a re-authentication that picked another account.
    static const String differentAccount = 'REAUTH_DIFFERENT_ACCOUNT';

    /// `Success(null)` means the user dismissed the re-authentication — nothing was
    /// deleted, and the screen goes back quietly. Same convention as `AuthService.signIn`.
    Future<Result<AccountDeletion?>> deleteAccount() async {
        for (var attempt = 1; ; attempt++) {
            switch (await _reauthenticate()) {
                case Failed(failure: final failure):
                    return Failed(failure);
                case Success(value: false):
                    return const Success(null);
                case Success():
                    break;
            }

            final result = await _repository.deleteAccount();
            switch (result) {
                case Success(value: final deletion):
                    await _endSession();
                    return Success(deletion);
                case Failed(failure: ForbiddenFailure(code: AccountRepository.recentSignInRequired))
                    when attempt == 1:
                    continue;
                case Failed(failure: final failure):
                    return Failed(failure);
            }
        }
    }

    /// `Success(true)` confirmed, `Success(false)` cancelled.
    Future<Result<bool>> _reauthenticate() async {
        final Reauthentication outcome;
        try {
            outcome = switch (await _credentials.currentProvider()) {
                SignInProvider.google => await _credentials.reauthenticate(),
                SignInProvider.facebook => await _facebookCredentials.reauthenticate(),
                // Signed in some other way (an emulator test account). Nothing to ask; the
                // Function still enforces freshness, and its refusal is what gets shown.
                null => Reauthentication.confirmed,
            };
        } on Object catch (_) {
            // A platform-channel failure from the Google/Facebook/Firebase plugin.
            return const Failed(UnknownFailure(message: 're-authentication failed'));
        }
        return switch (outcome) {
            Reauthentication.confirmed => const Success(true),
            Reauthentication.cancelled => const Success(false),
            Reauthentication.differentAccount =>
                const Failed(ForbiddenFailure(code: differentAccount)),
            Reauthentication.networkUnavailable => const Failed(NetworkFailure()),
        };
    }

    /// `AuthService.signOut` minus its first step, local data still last. Clearing the push token writes
    /// `users/{uid}`, which the Function has already deleted — the rules would refuse the
    /// write, and there is no token left server-side to clear anyway.
    Future<void> _endSession() async {
        await _sessionStore.clear();
        try {
            await _credentials.signOut();
        } on Object catch (_) {
            // The account is gone either way. A Firebase user object the SDK still holds
            // for a deleted uid cannot read or write anything, and the stored session
            // that routes to Home is already cleared.
        }
        try {
            await _clearLocalData?.call();
        } on Object catch (_) {
            // Same as the sign-out above: the account is gone, and this must not undo that
            // by surfacing as a failed deletion.
        }
    }
}
