import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/notify/application/push_registration_service.dart';

import 'support/auth_fakes.dart';

/// FCM token registration is an M3 deliverable even though the push is M4 (DEC-002).
void main() {
    late FakePushTokenSource source;
    late FakeFcmTokenRepository repository;
    late String language;

    setUp(() {
        source = FakePushTokenSource();
        repository = FakeFcmTokenRepository();
        language = 'km';
    });

    tearDown(() => source.refreshes.close());

    PushRegistrationService serviceUnder() =>
        PushRegistrationService(
            source: source,
            repository: repository,
            currentLanguage: () => language,
        );

    test('registers this device with the token FCM gave it', () async {
        final result = await serviceUnder().registerThisDevice();

        expect(result, isNotNull);
        expect(repository.registered, ['fcm-token-1']);
    });

    test('a declined permission is null, not a failure, and posts nothing', () async {
        source.permissionGranted = false;
        source.token = null;

        // A donor who refuses notifications is still a donor: still registered, still
        // matchable, just not alerted. Failing here would block sign-in over it.
        expect(await serviceUnder().registerThisDevice(), isNull);
        expect(repository.registered, isEmpty);
    });

    test('a device with no Play Services registers nothing and does not throw', () async {
        source.token = null;

        expect(await serviceUnder().registerThisDevice(), isNull);
        expect(repository.registered, isEmpty);
    });

    test('a rotated token is re-registered without user action', () async {
        final subscription = serviceUnder().watchTokenRefreshes();
        addTearDown(subscription.cancel);

        source.refreshes.add('fcm-token-2');
        await Future<void>.delayed(Duration.zero);

        // FCM rotates on reinstall and restore. A rotation that is not re-registered is a
        // donor who has silently stopped receiving alerts.
        expect(repository.registered, ['fcm-token-2']);
    });

    /// `users.language` decides which language `RequestAlertNotifier` sends an
    /// urgent-request alert in. Before this parameter existed no client ever wrote it, so
    /// every row kept the server's `'km'` default whatever the donor had the app set to.
    test('registers the language the app is currently in', () async {
        language = 'en';

        await serviceUnder().registerThisDevice();

        expect(repository.registeredLanguages, ['en']);
    });

    /// Read at call time, not captured: a donor who switches language after sign-in must
    /// not keep re-registering the language they started with on every token rotation.
    test('a token refresh carries the language as it is now, not as it was', () async {
        final subscription = serviceUnder().watchTokenRefreshes();
        addTearDown(subscription.cancel);

        language = 'en';
        source.refreshes.add('fcm-token-2');
        await Future<void>.delayed(Duration.zero);

        expect(repository.registered, ['fcm-token-2']);
        expect(repository.registeredLanguages, ['en']);
    });
}
