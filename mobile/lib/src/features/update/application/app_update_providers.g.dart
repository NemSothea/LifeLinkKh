// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appConfigRepositoryHash() => r'21fd993607593815348c71354ced50f5b4946e1a';

/// Overridden in `main.dart` with `FirestoreAppConfigRepository`. The default knows
/// nothing, so every widget test that boots `LifeLinkApp` gets no update notice and no
/// Firestore read without having to ask for either.
///
/// Copied from [appConfigRepository].
@ProviderFor(appConfigRepository)
final appConfigRepositoryProvider = Provider<AppConfigRepository>.internal(
  appConfigRepository,
  name: r'appConfigRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appConfigRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppConfigRepositoryRef = ProviderRef<AppConfigRepository>;
String _$installedVersionHash() => r'2b87a247e3ec0dbf7f3bee81b026c3f53ea270d9';

/// The real one by default: it is only asked once the config actually carries version
/// codes, which the default repository above never does.
///
/// Copied from [installedVersion].
@ProviderFor(installedVersion)
final installedVersionProvider = Provider<InstalledVersion>.internal(
  installedVersion,
  name: r'installedVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$installedVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InstalledVersionRef = ProviderRef<InstalledVersion>;
String _$updateDismissalStoreHash() => r'66fbd14a141809ca359a45a317adb5be6a6422b4';

/// Overridden in `main.dart` with the `SharedPreferences` store.
///
/// Copied from [updateDismissalStore].
@ProviderFor(updateDismissalStore)
final updateDismissalStoreProvider = Provider<UpdateDismissalStore>.internal(
  updateDismissalStore,
  name: r'updateDismissalStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateDismissalStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpdateDismissalStoreRef = ProviderRef<UpdateDismissalStore>;
String _$appConfigHash() => r'bf75ce4d27d11ed265c14f10411dfc1feff3a58f';

/// `config/app`, read once per launch and shared by the update check and the Me tab's
/// privacy link — one document read per app start, whatever the user opens.
///
/// `keepAlive` so switching tabs never reads it again. Never an error: offline, a
/// refused read or a missing document all become [AppConfig.none], because nothing in
/// this document is worth a failure card.
///
/// Copied from [appConfig].
@ProviderFor(appConfig)
final appConfigProvider = FutureProvider<AppConfig>.internal(
  appConfig,
  name: r'appConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppConfigRef = FutureProviderRef<AppConfig>;
String _$appUpdateControllerHash() => r'f166a72d8888fbd374a20ad919592e95a6a3e6cd';

/// What this launch shows about updates — see `UpdateGate`.
///
/// Copied from [AppUpdateController].
@ProviderFor(AppUpdateController)
final appUpdateControllerProvider =
    AsyncNotifierProvider<AppUpdateController, AppUpdate>.internal(
      AppUpdateController.new,
      name: r'appUpdateControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appUpdateControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppUpdateController = AsyncNotifier<AppUpdate>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
