import 'push_arrival.dart';

/// One entry under the bell: a copy of a push the portal sent this user, filed at
/// `users/{uid}/notifications/{id}` whether or not the push itself was delivered.
///
/// The server writes [title] and [body] in the language the push went out in, so the
/// list reads exactly like the notification the person may have swiped away.
final class AppNotification {
    const AppNotification({
        required this.id,
        required this.type,
        required this.title,
        required this.body,
        required this.createdAt,
        this.requestId,
        this.readAt,
    });

    final String id;

    /// One of [PushArrival]'s four types; anything else still lists, but opens nothing.
    final String type;
    final String? requestId;
    final String title;
    final String body;
    final DateTime createdAt;

    /// Null until the person opens the bell.
    final DateTime? readAt;

    bool get isUnread => readAt == null;

    /// The alert a donor answers, as opposed to news about the person's own request.
    bool get isRequestAlert => type == PushArrival.requestAlert;
}
