// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fcmTokenRepositoryHash() =>
    r'2db0776b6faf9f677033a3dce5395c4b175808ef';

/// Runs over the **intercepted** Dio: both `/auth/fcm-token` calls are authenticated, and
/// a 401 on either is repairable.
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
    r'7659127466f81cbbbfd8f59367c5c692dd6ed001';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
