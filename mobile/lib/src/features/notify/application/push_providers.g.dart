// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fcmTokenRepositoryHash() =>
    r'0c7854dc03f8b5721a9badbc0a6ba12d9ef6ed3b';

/// `users/{uid}.fcmToken` since ADR 0009 phase 3 — where `onRequestCreated` looks.
///
/// Copied from [fcmTokenRepository].
@ProviderFor(fcmTokenRepository)
final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>.internal(
  fcmTokenRepository,
  name: r'fcmTokenRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fcmTokenRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FcmTokenRepositoryRef = ProviderRef<FcmTokenRepository>;
String _$pushTokenSourceHash() => r'bde345f910be721d2fa7511b49f5980f14dbc506';

/// See also [pushTokenSource].
@ProviderFor(pushTokenSource)
final pushTokenSourceProvider = Provider<PushTokenSource>.internal(
  pushTokenSource,
  name: r'pushTokenSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushTokenSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushTokenSourceRef = ProviderRef<PushTokenSource>;
String _$pushRegistrationServiceHash() =>
    r'653b33dacb4221e634f48d91d175c51c94e36bdb';

/// See also [pushRegistrationService].
@ProviderFor(pushRegistrationService)
final pushRegistrationServiceProvider =
    Provider<PushRegistrationService>.internal(
      pushRegistrationService,
      name: r'pushRegistrationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pushRegistrationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushRegistrationServiceRef = ProviderRef<PushRegistrationService>;
String _$pushArrivalsHash() => r'5b904e4bac48ca587b5d241af4ad61b6ed59d038';

/// Pushes that arrive while the app is running. Empty by default — the same seam shape
/// as `authTokenGatewayProvider`: `main.dart` overrides it with the Firebase streams, and
/// every widget test gets a plain app with no platform channel behind it.
///
/// Copied from [pushArrivals].
@ProviderFor(pushArrivals)
final pushArrivalsProvider = StreamProvider<PushArrival>.internal(
  pushArrivals,
  name: r'pushArrivalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushArrivalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushArrivalsRef = StreamProviderRef<PushArrival>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
