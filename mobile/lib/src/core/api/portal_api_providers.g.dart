// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseFunctionsHash() => r'0f3c1c6f4d1e2a7b9c8d5e6f7a8b9c0d1e2f3a4b';

/// The `cloud_functions` instance the portal calls go through (ADR 0010). Only
/// `httpsCallableFromUrl` is used on it, so the region is irrelevant to the address — it
/// is set anyway, so a stray `httpsCallable(name)` would at least aim at Singapore rather
/// than `us-central1`. A provider rather than `FirebaseFunctions.instance` at the call
/// site, so no widget test reaches a platform channel.
///
/// Copied from [firebaseFunctions].
@ProviderFor(firebaseFunctions)
final firebaseFunctionsProvider = Provider<FirebaseFunctions>.internal(
  firebaseFunctions,
  name: r'firebaseFunctionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseFunctionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseFunctionsRef = ProviderRef<FirebaseFunctions>;
String _$portalApiHash() => r'5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c';

/// The portal's functions, at `Env.portalUrl`. Every repository that used to write
/// through a Cloud Function or a trigger-backed Firestore write calls this instead.
///
/// Copied from [portalApi].
@ProviderFor(portalApi)
final portalApiProvider = Provider<PortalApi>.internal(
  portalApi,
  name: r'portalApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$portalApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PortalApiRef = ProviderRef<PortalApi>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
