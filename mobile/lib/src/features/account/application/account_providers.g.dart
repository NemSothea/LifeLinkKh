// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$functionsHash() => r'4565d1a774f57a141f49bbcf2c07d7d71775b651';

/// A provider rather than `FirebaseFunctions.instanceFor` at the call site, so no widget
/// test reaches a platform channel. `main.dart` points the same instance at the emulator.
///
/// Copied from [functions].
@ProviderFor(functions)
final functionsProvider = Provider<FirebaseFunctions>.internal(
  functions,
  name: r'functionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$functionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FunctionsRef = ProviderRef<FirebaseFunctions>;
String _$accountRepositoryHash() => r'7596fd65db7e6be8b41141990ca3060d22a7c8ff';

/// See also [accountRepository].
@ProviderFor(accountRepository)
final accountRepositoryProvider = Provider<AccountRepository>.internal(
  accountRepository,
  name: r'accountRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AccountRepositoryRef = ProviderRef<AccountRepository>;
String _$accountDeletionServiceHash() =>
    r'54b3f685b22f14afc54af974f5009cad4288ab72';

/// See also [accountDeletionService].
@ProviderFor(accountDeletionService)
final accountDeletionServiceProvider =
    Provider<AccountDeletionService>.internal(
      accountDeletionService,
      name: r'accountDeletionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$accountDeletionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AccountDeletionServiceRef = ProviderRef<AccountDeletionService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
