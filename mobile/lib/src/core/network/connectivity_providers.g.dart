// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isOfflineHash() => r'7b824080887416322aa6f66488a95a5bcd77906c';

/// True while the phone has no network interface up at all — airplane mode, wifi and
/// mobile data both off. What the offline banner reads.
///
/// An interface, not the internet: a phone on hotel wifi with no uplink reports
/// "connected" here. That case still lands on the section's own [NetworkFailure] copy
/// after the Dio timeout, so the banner only has to be right when it *does* show.
///
/// A plugin that is not there (every widget test) reads as online: a banner that
/// appears in tests because a platform channel is missing would be a lie.
///
/// Copied from [isOffline].
@ProviderFor(isOffline)
final isOfflineProvider = StreamProvider<bool>.internal(
  isOffline,
  name: r'isOfflineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOfflineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOfflineRef = StreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
