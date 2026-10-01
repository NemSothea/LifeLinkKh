import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/avatar_account.dart';
import '../domain/avatar_spec.dart';

/// The picked avatar as `users/{uid}.avatar`, in `AvatarSpec.encode`'s `m:123` shape — the
/// only shape the Security Rules accept there.
final class FirestoreAvatarAccount implements AvatarAccount {
    FirestoreAvatarAccount(this._db);

    final FirebaseFirestore _db;

    @override
    Future<AvatarSpec?> fetch(String userId) async {
        try {
            final snapshot = await _db.collection('users').doc(userId).get();
            return AvatarSpec.decode(snapshot.data()?['avatar'] as String?);
        } on Object catch (_) {
            // Offline, or no doc yet: the default face, and the next sign-in tries again.
            return null;
        }
    }

    @override
    Future<void> save(String userId, AvatarSpec spec) async {
        try {
            // An update, not a set: the doc is created at sign-in, and a set here could not
            // carry the role and createdAt the rules require of a new one.
            await _db.collection('users').doc(userId).update({
                'avatar': spec.encode(),
                'updatedAt': FieldValue.serverTimestamp(),
            });
        } on Object catch (_) {
            // Kept on the phone regardless; the account copy is only for a reinstall.
        }
    }
}
