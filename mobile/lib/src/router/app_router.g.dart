// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appRouterHash() => r'b5bee57cf62f70cc18d31d2ba07bf9d3e9a64859';

/// Declarative route table. go_router is here from M2 because M4 opens a specific request
/// from an FCM notification tap — that is a deep link, and retrofitting one onto
/// hand-rolled navigation is the expensive way to do it.
///
/// A provider rather than a global as of M3: the redirect has to read the session, and the
/// session is a provider. `keepAlive` because a router that is disposed and rebuilt loses
/// the navigation stack.
///
/// Copied from [appRouter].
@ProviderFor(appRouter)
final appRouterProvider = Provider<GoRouter>.internal(
  appRouter,
  name: r'appRouterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRouterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRouterRef = ProviderRef<GoRouter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
