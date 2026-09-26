// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchSyncDaoHash() => r'db646881a287234d7943167342e318de41af1ce6';

/// See also [matchSyncDao].
@ProviderFor(matchSyncDao)
final matchSyncDaoProvider = Provider<MatchSyncDao>.internal(
  matchSyncDao,
  name: r'matchSyncDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$matchSyncDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchSyncDaoRef = ProviderRef<MatchSyncDao>;
String _$remoteMatchRepositoryHash() =>
    r'f52ecd9446f6b676b1e3a10a35e138f7aecc7865';

/// The network half, on its own. The sync engine drains through this one: going
/// through [matchRepositoryProvider] would re-queue every write it just sent.
///
/// Copied from [remoteMatchRepository].
@ProviderFor(remoteMatchRepository)
final remoteMatchRepositoryProvider = Provider<MatchRepository>.internal(
  remoteMatchRepository,
  name: r'remoteMatchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteMatchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RemoteMatchRepositoryRef = ProviderRef<MatchRepository>;
String _$matchRepositoryHash() => r'ee8644f561ffda88a4a1b7bc739de9f7cb2df1f9';

/// The swap. Everything above this line — service, notifier, every widget — was
/// written against [MatchRepository] and did not change when SQLite arrived.
///
/// Copied from [matchRepository].
@ProviderFor(matchRepository)
final matchRepositoryProvider = Provider<MatchRepository>.internal(
  matchRepository,
  name: r'matchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$matchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchRepositoryRef = ProviderRef<MatchRepository>;
String _$matchSyncServiceHash() => r'b1f9d09db8f5b66752c233e14c5e1d7a17fc4d72';

/// See also [matchSyncService].
@ProviderFor(matchSyncService)
final matchSyncServiceProvider = Provider<MatchSyncService>.internal(
  matchSyncService,
  name: r'matchSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$matchSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchSyncServiceRef = ProviderRef<MatchSyncService>;
String _$matchServiceHash() => r'237c514b77d5c417e1f46f57cdaec3ae1ee14a7d';

/// See also [matchService].
@ProviderFor(matchService)
final matchServiceProvider = Provider<MatchService>.internal(
  matchService,
  name: r'matchServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$matchServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchServiceRef = ProviderRef<MatchService>;
String _$myMatchesControllerHash() =>
    r'af75ec609f05bc2d71194849f447ae2e0794182c';

/// The donor's inbox. `keepAlive` so it survives navigating into and back out of
/// a match's detail screen.
///
/// Copied from [MyMatchesController].
@ProviderFor(MyMatchesController)
final myMatchesControllerProvider =
    AsyncNotifierProvider<MyMatchesController, List<Match>>.internal(
      MyMatchesController.new,
      name: r'myMatchesControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myMatchesControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyMatchesController = AsyncNotifier<List<Match>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
