// `show`, because cloud_functions exports a `Result` of its own (streaming callables)
// that would shadow the app's.
import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctions, FirebaseFunctionsException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/account_deletion.dart';
import '../domain/account_repository.dart';

/// The real [AccountRepository]: the `deleteAccount` callable in `asia-southeast1`
/// (`firebase/functions/src/delete-account.js`).
///
/// The Function's refusals arrive as `failed-precondition` with the reason in
/// `details.code`. They are read from there and nowhere else — the message beside them is
/// English prose meant for a log, and switching on it would break the day it is reworded.
final class FunctionsAccountRepository implements AccountRepository {
    FunctionsAccountRepository(this._functions);

    final FirebaseFunctions _functions;

    @override
    Future<Result<AccountDeletion>> deleteAccount() async {
        final Object? data;
        try {
            data = (await _functions.httpsCallable('deleteAccount').call<Object?>()).data;
        } on FirebaseFunctionsException catch (error) {
            return Failed(
                accountFailureFrom(code: error.code, details: error.details, message: error.message),
            );
        }
        // An answer without the counts is still a deleted account: the Function deletes
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

/// What a `deleteAccount` refusal means to the app. Takes the exception's parts rather than
/// the exception, whose constructor is `@protected`, so the mapping is testable.
Failure accountFailureFrom({required String code, Object? details, String? message}) {
    final reason = details is Map ? details['code'] : null;
    if (code == 'failed-precondition' &&
        (reason == AccountRepository.recentSignInRequired ||
            reason == AccountRepository.adminAccount)) {
        return ForbiddenFailure(message: message ?? code, code: reason as String);
    }
    // Everything else means what it means for Firestore: `unavailable` is the plugin's code
    // for an IOException (no connection), `unauthenticated` a missing token.
    return failureFromFirebase(FirebaseException(plugin: 'firebase_functions', code: code));
}
