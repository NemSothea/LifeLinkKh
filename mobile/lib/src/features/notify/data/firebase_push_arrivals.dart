import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/push_arrival.dart';

/// `firebase_messaging`'s two "the app is running and a push arrived" streams, as one.
///
/// Only wired in `main.dart`. Everywhere else the seam in `push_providers.dart` stays at
/// its empty default, so no widget test touches a Firebase platform channel.
Stream<PushArrival> firebasePushArrivals() {
    final controller = StreamController<PushArrival>();
    final subscriptions = <StreamSubscription<RemoteMessage>>[];
    controller
        ..onListen = () {
            void Function(RemoteMessage) forward({required bool foreground}) =>
                (message) => controller.add(
                    PushArrival(
                        message.data['type'] as String? ?? '',
                        requestId: message.data['requestId'] as String?,
                        foreground: foreground,
                    ),
                );
            subscriptions
                ..add(FirebaseMessaging.onMessage.listen(forward(foreground: true)))
                ..add(
                    FirebaseMessaging.onMessageOpenedApp.listen(forward(foreground: false)),
                );
        }
        ..onCancel = () async {
            for (final subscription in subscriptions) {
                await subscription.cancel();
            }
        };
    return controller.stream;
}
