import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/push_token_source.dart';

/// The real [PushTokenSource], over `firebase_messaging`.
final class FirebasePushTokenSource implements PushTokenSource {
    FirebasePushTokenSource({FirebaseMessaging? messaging})
        : _messaging = messaging ?? FirebaseMessaging.instance;

    final FirebaseMessaging _messaging;

    @override
    Future<bool> requestPermission() async {
        final settings = await _messaging.requestPermission();
        // `provisional` is iOS quiet notifications. Counted as granted: a quiet urgent-request
        // alert still reaches the donor, and treating it as a refusal would drop them.
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    @override
    Future<String?> currentToken() async {
        try {
            return await _messaging.getToken();
        } on Object catch (_) {
            // No Play Services, or a device with FCM disabled. Not an error the donor can
            // act on, and not a reason to fail sign-in.
            return null;
        }
    }

    @override
    Stream<String> tokenRefreshes() => _messaging.onTokenRefresh;
}
