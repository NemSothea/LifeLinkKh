import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firebase/firestore_providers.dart';
import '../../../core/settings/locale_controller.dart';
import '../data/firestore_fcm_token_repository.dart';
import '../data/firebase_push_token_source.dart';
import '../domain/fcm_token_repository.dart';
import '../domain/push_arrival.dart';
import '../domain/push_token_source.dart';
import 'push_registration_service.dart';

part 'push_providers.g.dart';

/// `users/{uid}.fcmToken` since ADR 0009 phase 3 — where `onRequestCreated` looks.
@Riverpod(keepAlive: true)
FcmTokenRepository fcmTokenRepository(FcmTokenRepositoryRef ref) => FirestoreFcmTokenRepository(
    ref.watch(firestoreProvider),
    currentUid: ref.watch(currentUidProvider),
    currentDisplayName: ref.watch(currentDisplayNameProvider),
);

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
