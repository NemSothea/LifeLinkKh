// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthRepositoryHash() => r'58a012e854292b287ae0fbcd5f79e845bf8b6c60';

/// The composition root for this feature — deliberately the only file that names a
/// concrete implementation. `application/` importing `data/` is an outward arrow and
/// the one the course sanctions, because it is what keeps every other layer free of
/// the concrete type.
///
/// Copied from [healthRepository].
@ProviderFor(healthRepository)
final healthRepositoryProvider = Provider<HealthRepository>.internal(
  healthRepository,
  name: r'healthRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$healthRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HealthRepositoryRef = ProviderRef<HealthRepository>;
String _$healthServiceHash() => r'8d6001d74f5563969853cf308f16b22c10d18f8b';

/// `ref.watch`, not `ref.read`: a test that overrides [healthRepositoryProvider] must
/// have that override reach the Service.
///
/// Copied from [healthService].
@ProviderFor(healthService)
final healthServiceProvider = Provider<HealthService>.internal(
  healthService,
  name: r'healthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$healthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HealthServiceRef = ProviderRef<HealthService>;
String _$healthStatusHash() => r'0ac28ea9bfc096bb83f885bd502072d18a0ad65d';

/// `keepAlive` on the two above because a repository and a service are singleton-like
/// and cheap to keep; this one is left autoDispose so the check re-runs on a fresh
/// visit rather than serving a stale answer.
///
/// Still a future-provider rather than an `AsyncNotifier`, which is Week 5's subject.
/// It lands with the M3 screens, where there is a retry and an empty state to build.
///
/// Copied from [healthStatus].
@ProviderFor(healthStatus)
final healthStatusProvider = AutoDisposeFutureProvider<HealthStatus>.internal(
  healthStatus,
  name: r'healthStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$healthStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HealthStatusRef = AutoDisposeFutureProviderRef<HealthStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
