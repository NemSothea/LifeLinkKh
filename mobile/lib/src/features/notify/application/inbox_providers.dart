import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/app_notification.dart';
import '../domain/notification_inbox_repository.dart';

part 'inbox_providers.g.dart';

/// Overridden in `main.dart` with the Firestore inbox. The default is always empty, so
/// every widget test that builds Home gets a bell with no badge and no listener.
@Riverpod(keepAlive: true)
NotificationInboxRepository notificationInboxRepository(
    NotificationInboxRepositoryRef ref,
) =>
    const EmptyNotificationInbox();

/// The signed-in user's inbox, live. Empty signed out; re-subscribes on the next sign-in,
/// because it watches only the user's id.
@Riverpod(keepAlive: true)
Stream<List<AppNotification>> inbox(InboxRef ref) {
    final uid = ref.watch(authControllerProvider.select((auth) => auth.valueOrNull?.user.id));
    if (uid == null) return Stream.value(const []);
    return ref.watch(notificationInboxRepositoryProvider).watch(uid);
}

/// Ids this launch has marked read, ahead of the server's answer.
///
/// `readAt` is the server's clock, and a snapshot shows a pending server timestamp as
/// null — so without this the badge would come back for the round trip, and stay back
/// for as long as the phone is offline. Reset on every change of user.
@Riverpod(keepAlive: true)
class InboxReadMarks extends _$InboxReadMarks {
    @override
    Set<String> build() {
        ref.watch(authControllerProvider.select((auth) => auth.valueOrNull?.user.id));
        return const {};
    }

    /// Everything currently unread, marked read — what opening the bell does.
    Future<void> markAllRead() async {
        final uid = ref.read(authControllerProvider).valueOrNull?.user.id;
        if (uid == null) return;
        final unread = [
            for (final entry in ref.read(inboxProvider).valueOrNull ?? const <AppNotification>[])
                if (entry.isUnread && !state.contains(entry.id)) entry.id,
        ];
        if (unread.isEmpty) return;
        // State first, write second, like `AvatarController.pick`: the badge goes the
        // moment the list opens, and a failed write only means it is counted again next launch.
        state = {...state, ...unread};
        try {
            await ref.read(notificationInboxRepositoryProvider).markRead(uid, unread);
        } on Object catch (_) {
            // Offline writes are queued by the SDK; anything else is not worth a failure card.
        }
    }
}

/// The number on the bell.
@Riverpod(keepAlive: true)
int unreadNotificationCount(UnreadNotificationCountRef ref) {
    final entries = ref.watch(inboxProvider).valueOrNull ?? const <AppNotification>[];
    final marked = ref.watch(inboxReadMarksProvider);
    return entries.where((e) => e.isUnread && !marked.contains(e.id)).length;
}
