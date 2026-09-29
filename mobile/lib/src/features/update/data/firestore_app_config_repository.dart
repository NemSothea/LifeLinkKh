import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/app_config.dart';
import '../domain/app_config_repository.dart';

/// `config/app` on Firestore — public, readable signed out, written only by the admin
/// portal's `setAppConfig` function or the operator's release script (`firebase/`),
/// never by the app.
///
/// Parsing is forgiving field by field: a value of the wrong type is dropped, not fatal.
/// The document is hand-maintained, and one typo in `latestVersionName` must not also
/// cost every phone the `minVersionCode` check beside it.
final class FirestoreAppConfigRepository implements AppConfigRepository {
    FirestoreAppConfigRepository(this._db);

    final FirebaseFirestore _db;

    static const String collection = 'config';
    static const String document = 'app';

    @override
    Future<Result<AppConfig>> fetch() async {
        try {
            final snapshot = await _db.collection(collection).doc(document).get();
            final data = snapshot.data();
            if (data == null) return const Success(AppConfig.none);
            return Success(appConfigFrom(data));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }
}

/// The document's fields as an [AppConfig]. Top-level so the tolerance rules are
/// testable without a Firestore round-trip.
AppConfig appConfigFrom(Map<String, Object?> data) {
    // `num`, not `int`: a number typed into the Firebase console by hand can be stored
    // as a double. A fractional version code is nonsense and is dropped.
    int? versionCode(String key) {
        final value = data[key];
        if (value is int) return value;
        if (value is double && value == value.truncateToDouble()) return value.toInt();
        return null;
    }

    String? text(String key) => data[key] is String ? data[key] as String : null;

    final name = data['latestVersionName'];
    return AppConfig(
        minVersionCode: versionCode('minVersionCode'),
        latestVersionCode: versionCode('latestVersionCode'),
        latestVersionName: name is String && name.trim().isNotEmpty ? name.trim() : null,
        downloadUrl: webLinkFrom(data['downloadUrl'], allowHttp: kDebugMode),
        privacyUrl: webLinkFrom(data['privacyUrl'], allowHttp: kDebugMode),
        releaseNotes: ReleaseNotes.of(en: text('releaseNotesEn'), km: text('releaseNotesKm')),
    );
}
