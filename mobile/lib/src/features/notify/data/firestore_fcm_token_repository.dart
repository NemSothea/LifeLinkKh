// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/fcm_token_repository.dart';

/// The push token on `users/{uid}` (ADR 0009) — what `POST`/`DELETE /auth/fcm-token` was.
///
/// `onRequestCreated` reads `fcmToken` and `language` from here to push a donor, so this
/// document is also where the user record starts: the first registration creates it.
final class FirestoreFcmTokenRepository implements FcmTokenRepository {
    FirestoreFcmTokenRepository(
        this._db, {
        required String? Function() currentUid,
        required String? Function() currentDisplayName,
    })  : _currentUid = currentUid,
          _currentDisplayName = currentDisplayName;

    final FirebaseFirestore _db;
    final String? Function() _currentUid;
    final String? Function() _currentDisplayName;

    @override
    Future<Result<void>> register(String fcmToken, {String? language}) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        try {
            final ref = _db.collection('users').doc(uid);
            if ((await ref.get()).exists) {
                await ref.update({
                    'fcmToken': fcmToken,
                    // Absent means "leave it", as the endpoint read a missing key.
                    'language': ?language,
                    'updatedAt': FieldValue.serverTimestamp(),
                });
            } else {
                final name = _currentDisplayName()?.trim();
                await ref.set({
                    if (name != null && name.isNotEmpty) 'displayName': name,
                    'language': language ?? 'km',
                    // Self-service only; staff roles are claims, never this field.
                    'role': 'DONOR',
                    'fcmToken': fcmToken,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                });
            }
            return const Success(null);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }

    @override
    Future<Result<void>> clear() async {
        final uid = _currentUid();
        // Signed out already: there is no token of ours left to clear.
        if (uid == null) return const Success(null);
        try {
            final ref = _db.collection('users').doc(uid);
            if (!(await ref.get()).exists) return const Success(null);
            await ref.update({'fcmToken': null, 'updatedAt': FieldValue.serverTimestamp()});
            return const Success(null);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }
}
