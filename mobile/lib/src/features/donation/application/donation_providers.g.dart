// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$donationRepositoryHash() =>
    r'5b8dbf89ce5d4b9d61d15be07d8743690ca8b980';

/// See also [donationRepository].
@ProviderFor(donationRepository)
final donationRepositoryProvider = Provider<DonationRepository>.internal(
  donationRepository,
  name: r'donationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$donationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DonationRepositoryRef = ProviderRef<DonationRepository>;
String _$donationServiceHash() => r'5db1c18bccb68f8562b7ea319dbcb5f928d99428';

/// See also [donationService].
@ProviderFor(donationService)
final donationServiceProvider = Provider<DonationService>.internal(
  donationService,
  name: r'donationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$donationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DonationServiceRef = ProviderRef<DonationService>;
String _$myDonationsControllerHash() =>
    r'08e20da4da3a5e04f16556757137a265df80c480';

/// The donor's own donation history, newest first.
///
/// Copied from [MyDonationsController].
@ProviderFor(MyDonationsController)
final myDonationsControllerProvider =
    AsyncNotifierProvider<MyDonationsController, List<Donation>>.internal(
      MyDonationsController.new,
      name: r'myDonationsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myDonationsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyDonationsController = AsyncNotifier<List<Donation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
