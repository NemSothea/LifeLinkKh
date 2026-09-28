import '../../../core/api/portal_api.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/portal_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/account_deletion.dart';
import '../domain/account_repository.dart';

/// The real [AccountRepository]: the portal's `deleteAccount` function
/// (`frontend/src/server/delete-account.js`, ADR 0010).
///
/// The function's refusals arrive as `failed-precondition` with the reason in
/// `details.code`. They are read from there and nowhere else — the message beside them is
/// English prose meant for a log, and switching on it would break the day it is reworded.
final class FunctionsAccountRepository implements AccountRepository {
    FunctionsAccountRepository(this._api);

    final PortalApi _api;

    @override
    Future<Result<AccountDeletion>> deleteAccount() async {
        final Object? data;
        try {
            data = await _api.call('deleteAccount');
        } on PortalCallException catch (error) {
            return Failed(
                accountFailureFrom(code: error.code, details: error.details, message: error.message),
            );
        }
        // An answer without the counts is still a deleted account: the function deletes
        // the Auth user last and returns after it. Reporting zeros is honest; failing here
        // would tell someone whose account is gone that it is not.
        final counts = data is Map ? data : const {};
        int count(String key) => (counts[key] as num?)?.toInt() ?? 0;
        return Success(AccountDeletion(
            requestsClosed: count('requestsClosed'),
            acceptancesWithdrawn: count('acceptancesWithdrawn'),
            recordsAnonymised: count('recordsAnonymised'),
        ));
    }
}

/// What a `deleteAccount` refusal means to the app. Takes the refusal's parts rather than
/// the exception, so the mapping is testable on its own.
Failure accountFailureFrom({required String code, Object? details, String? message}) {
    final reason = details is Map ? details['code'] : null;
    if (code == 'failed-precondition' &&
        (reason == AccountRepository.recentSignInRequired ||
            reason == AccountRepository.adminAccount)) {
        return ForbiddenFailure(message: message ?? code, code: reason as String);
    }
    // Everything else means what it means for any portal call: `unavailable` is the plugin's
    // code for an IOException (no connection), `unauthenticated` a missing token.
    return failureFromPortalCall(PortalCallException(code: code, details: details, message: message));
}
