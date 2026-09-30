// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$avatarStoreHash() => r'0000000000000000000000000000000000000000';

/// Overridden in `main.dart` with the `SharedPreferences` store. The default forgets at
/// exit, so no widget test has to stub a platform channel to build the Me tab.
///
/// Copied from [avatarStore].
@ProviderFor(avatarStore)
final avatarStoreProvider = Provider<AvatarStore>.internal(
  avatarStore,
  name: r'avatarStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$avatarStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvatarStoreRef = ProviderRef<AvatarStore>;
String _$avatarControllerHash() => r'0000000000000000000000000000000000000000';

/// The signed-in user's avatar, or null with nobody signed in.
///
/// Copied from [AvatarController].
@ProviderFor(AvatarController)
final avatarControllerProvider =
    NotifierProvider<AvatarController, AvatarSpec?>.internal(
      AvatarController.new,
      name: r'avatarControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$avatarControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AvatarController = Notifier<AvatarSpec?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
