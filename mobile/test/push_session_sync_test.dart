import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';
import 'package:lifelink_kh/src/features/notify/application/push_session_sync.dart';

import 'support/auth_fakes.dart';

/// The two registrations interactive sign-in never covered: a session restored from the
/// keystore, and a token FCM rotated while the app was running. Either one missed is a
/// signed-in user whose phone silently stops receiving alerts.
void main() {
    late FakeFcmTokenRepository fcm;
    late FakePushTokenSource pushTokens;

    setUp(() {
        fcm = FakeFcmTokenRepository();
        pushTokens = FakePushTokenSource();
    });

    tearDown(() => pushTokens.refreshes.close());

    ProviderContainer start({required bool storedSession}) {
        final container = ProviderContainer(
            overrides: [
                authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                sessionStoreProvider.overrideWithValue(
                    FakeSessionStore(storedSession ? testSession() : null),
                ),
                googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                telegramAuthRepositoryProvider.overrideWithValue(FakeTelegramAuthRepository()),
                fcmTokenRepositoryProvider.overrideWithValue(fcm),
                pushTokenSourceProvider.overrideWithValue(pushTokens),
            ],
        );
        addTearDown(container.dispose);
        container.read(pushSessionSyncProvider);
        return container;
    }

    /// Lets the keystore read, the registration POST and any stream event settle.
    Future<void> settle(ProviderContainer container) async {
        await container.read(authControllerProvider.future);
        await pumpEventQueue();
    }

    test('a restored session re-registers this device', () async {
        final container = start(storedSession: true);
        await settle(container);

        expect(fcm.registered, ['fcm-token-1']);
    });

    test('a launch with no stored session registers nothing', () async {
        final container = start(storedSession: false);
        await settle(container);

        expect(fcm.registered, isEmpty);
    });

    /// Sign-in registers on its own path. This must not add a second POST for the same
    /// token.
    test('an interactive sign-in is registered once, not twice', () async {
        final container = start(storedSession: false);
        await settle(container);

        await container.read(authControllerProvider.notifier).signIn();
        await pumpEventQueue();

        expect(fcm.registered, ['fcm-token-1']);
    });

    test('a token rotated while signed in is re-registered', () async {
        final container = start(storedSession: true);
        await settle(container);

        pushTokens.refreshes.add('fcm-token-2');
        await pumpEventQueue();

        expect(fcm.registered, ['fcm-token-1', 'fcm-token-2']);
    });

    test('a rotation after signing out is not registered', () async {
        final container = start(storedSession: true);
        await settle(container);

        await container.read(authControllerProvider.notifier).signOut();
        await pumpEventQueue();
        pushTokens.refreshes.add('fcm-token-2');
        await pumpEventQueue();

        expect(fcm.registered, ['fcm-token-1']);
    });
}
