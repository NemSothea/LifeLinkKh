// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import '../../../core/database/app_database.dart';
import '../../notify/domain/push_token_source.dart';

/// What this phone holds about the user who is leaving, and how to drop it
/// (SEC-REVIEW-003 F-07, F-20). Run by `AuthService.signOut` and
/// `AccountDeletionService`, after the Firebase session is gone.
///
/// A phone in Phnom Penh is often shared. Without this the next person to sign in on it
/// inherits the last donor's answers, the requester phone numbers the Firestore cache
/// kept, and a write queue that could replay under their own account.
///
/// Every step runs even when the one before it failed, and none of them throws: the
/// user asked to leave, and a half-cleared phone is still better than a sign-out that
/// never finishes.
final class LocalDataEraser {
    LocalDataEraser({
        required AppDatabase database,
        required PushTokenSource pushTokens,
        required Future<void> Function() clearFirestoreCache,
    })  : _database = database,
          _pushTokens = pushTokens,
          _clearFirestoreCache = clearFirestoreCache;

    final AppDatabase _database;
    final PushTokenSource _pushTokens;

    /// `terminate()` then `clearPersistence()` on the app's Firestore instance. A callback
    /// so the tests need no platform channel; `localDataEraserProvider` supplies the real
    /// one.
    final Future<void> Function() _clearFirestoreCache;

    Future<void> erase() async {
        try {
            await _pushTokens.deleteToken();
        } on Object catch (_) {
            // The contract says it does not throw; a sign-out does not bet on that.
        }
        try {
            await _database.deleteAllRows();
        } on Object catch (_) {
            // The file could not be opened. Nothing was cached in it, then.
        }
        try {
            await _clearFirestoreCache();
        } on Object catch (_) {
            // A read still in flight keeps the instance running and `clearPersistence`
            // refuses. The next sign-in reads the server either way; the rules decide what
            // it may see.
        }
    }
}
