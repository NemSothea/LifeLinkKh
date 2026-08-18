// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$donorRepositoryHash() => r'6d38fb2c1901fdd6e0eac7b84571c7cf3ea1bfc5';

/// See also [donorRepository].
@ProviderFor(donorRepository)
final donorRepositoryProvider = Provider<DonorRepository>.internal(
  donorRepository,
  name: r'donorRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$donorRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DonorRepositoryRef = ProviderRef<DonorRepository>;
String _$donorServiceHash() => r'1c80ea1302a386ff8959aa0b90b9294ed1b2014a';

/// See also [donorService].
@ProviderFor(donorService)
final donorServiceProvider = Provider<DonorService>.internal(
  donorService,
  name: r'donorServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$donorServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DonorServiceRef = ProviderRef<DonorService>;
String _$districtsHash() => r'cb026e74c2009962541d26012a98861f8e0d35d2';

/// The district dropdown's options.
///
/// `keepAlive` because this is reference data that does not change during a session, and
/// re-fetching it every time the location step is rebuilt would put a spinner in the middle
/// of a form.
///
/// Copied from [districts].
@ProviderFor(districts)
final districtsProvider = FutureProvider<List<District>>.internal(
  districts,
  name: r'districtsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$districtsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DistrictsRef = FutureProviderRef<List<District>>;
String _$donorProfileControllerHash() =>
    r'688e00e0949b6d3e1928bccb840729b505800da0';

/// The donor's own profile. `AsyncData(null)` means "no profile yet", which is where every
/// donor starts and is the state that routes into setup.
///
/// Copied from [DonorProfileController].
@ProviderFor(DonorProfileController)
final donorProfileControllerProvider =
    AsyncNotifierProvider<DonorProfileController, DonorProfile?>.internal(
      DonorProfileController.new,
      name: r'donorProfileControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$donorProfileControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DonorProfileController = AsyncNotifier<DonorProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
