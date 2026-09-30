import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_notification.dart';
import '../domain/notification_inbox_repository.dart';

/// `users/{uid}/notifications` on Firestore. Filed by the portal's server beside each push
/// (`frontend/src/server/push.js` fileInInbox); the app only reads it and stamps `readAt`.
final class FirestoreNotificationInboxRepository implements NotificationInboxRepository {
    FirestoreNotificationInboxRepository(this._db);

    final FirebaseFirestore _db;

    /// Enough for weeks of alerts in a busy district; older ones are not worth a read each.
    static const int limit = 50;

    CollectionReference<Map<String, Object?>> _inbox(String uid) =>
        _db.collection('users').doc(uid).collection('notifications');

    @override
    Stream<List<AppNotification>> watch(String uid) => _inbox(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => [
            for (final doc in snapshot.docs) ?notificationFrom(doc.id, doc.data()),
        ]);

    @override
    Future<void> markRead(String uid, Iterable<String> ids) async {
        if (ids.isEmpty) return;
        // One batch, so opening the bell costs one round trip however many were unread.
        // Queued by the SDK when offline and sent on reconnect, like every other write.
        final batch = _db.batch();
        for (final id in ids) {
            batch.update(_inbox(uid).doc(id), {'readAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
    }
}

/// One document as an [AppNotification], or null when it is missing what a row needs.
/// Top-level so the parsing is testable without a snapshot.
///
/// A `createdAt` still pending on the server's clock (a local snapshot of a write the
/// server has not stamped yet) reads as now — it is, give or take a round trip.
AppNotification? notificationFrom(String id, Map<String, Object?> data) {
    final type = data['type'];
    final title = data['title'];
    final body = data['body'];
    if (type is! String || title is! String || body is! String) return null;
    final createdAt = data['createdAt'];
    final readAt = data['readAt'];
    final requestId = data['requestId'];
    return AppNotification(
        id: id,
        type: type,
        requestId: requestId is String ? requestId : null,
        title: title,
        body: body,
        createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
        readAt: readAt is Timestamp ? readAt.toDate() : null,
    );
}
