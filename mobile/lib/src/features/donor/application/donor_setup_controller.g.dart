// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donor_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$donorSetupHash() => r'b735dcbe21ae76f9d3e0c7c2ddaf6b29488f9301';

/// Drives the setup wizard. `autoDispose` (the default) on purpose: leaving the flow discards
/// a half-filled draft rather than showing it again days later.
///
/// Copied from [DonorSetup].
@ProviderFor(DonorSetup)
final donorSetupProvider =
    AutoDisposeNotifierProvider<DonorSetup, DonorSetupState>.internal(
      DonorSetup.new,
      name: r'donorSetupProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$donorSetupHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DonorSetup = AutoDisposeNotifier<DonorSetupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
