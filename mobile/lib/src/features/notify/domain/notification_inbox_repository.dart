import 'app_notification.dart';

/// The bell's inbox, `users/{uid}/notifications`.
abstract interface class NotificationInboxRepository {
    /// Newest first, capped — the bell is a recent-news list, not an archive. Emits again
    /// whenever the server files an entry, so a push arriving in the foreground shows up
    /// under the bell without anyone refreshing.
    Stream<List<AppNotification>> watch(String uid);

    /// Stamps [ids] read. The rules allow nothing else: read stays read.
    Future<void> markRead(String uid, Iterable<String> ids);
}

/// The default binding: always empty. `main.dart` overrides it with the Firestore one,
/// so no widget test that builds Home opens a Firestore listener without asking to.
final class EmptyNotificationInbox implements NotificationInboxRepository {
    const EmptyNotificationInbox();

    @override
    Stream<List<AppNotification>> watch(String uid) => Stream.value(const []);

    @override
    Future<void> markRead(String uid, Iterable<String> ids) async {}
}
