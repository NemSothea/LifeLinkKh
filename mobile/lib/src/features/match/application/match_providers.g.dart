// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchRepositoryHash() => r'106024f896120895f1e64ffe2b91b76b8d11d157';

/// See also [matchRepository].
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
    r'd3f329001986d18566075fbce7eb84bf46ca4550';

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
