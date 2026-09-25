import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/settings/locale_controller.dart';
import '../data/dio_fcm_token_repository.dart';
import '../data/firebase_push_token_source.dart';
import '../domain/fcm_token_repository.dart';
import '../domain/push_arrival.dart';
import '../domain/push_token_source.dart';
import 'push_registration_service.dart';

part 'push_providers.g.dart';

/// Runs over the **intercepted** Dio: both `/auth/fcm-token` calls are authenticated, and
/// a 401 on either is repairable.
@Riverpod(keepAlive: true)
FcmTokenRepository fcmTokenRepository(FcmTokenRepositoryRef ref) =>
    DioFcmTokenRepository(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(PushTokenSourceRef ref) => FirebasePushTokenSource();

@Riverpod(keepAlive: true)
PushRegistrationService pushRegistrationService(PushRegistrationServiceRef ref) =>
    PushRegistrationService(
        source: ref.watch(pushTokenSourceProvider),
        repository: ref.watch(fcmTokenRepositoryProvider),
        // `ref.read` inside a callback, not `ref.watch`: watching would rebuild this
        // keepAlive service on every language change and drop the token-refresh
        // subscription `pushSessionSync` holds against it.
        currentLanguage: () => ref.read(localeControllerProvider).languageCode,
    );

/// Pushes that arrive while the app is running. Empty by default — the same seam shape
/// as `authTokenGatewayProvider`: `main.dart` overrides it with the Firebase streams, and
/// every widget test gets a plain app with no platform channel behind it.
@Riverpod(keepAlive: true)
Stream<PushArrival> pushArrivals(PushArrivalsRef ref) => const Stream.empty();
