// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionStoreHash() => r'f0f028e1a9dac98d0b6de34dcd442dac885ef7a9';

/// See also [sessionStore].
@ProviderFor(sessionStore)
final sessionStoreProvider = Provider<SessionStore>.internal(
  sessionStore,
  name: r'sessionStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionStoreRef = ProviderRef<SessionStore>;
String _$googleCredentialsHash() => r'1e4ddbe61ba7c5db609eb81e9b69776095ceb82a';

/// See also [googleCredentials].
@ProviderFor(googleCredentials)
final googleCredentialsProvider = Provider<GoogleCredentials>.internal(
  googleCredentials,
  name: r'googleCredentialsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$googleCredentialsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoogleCredentialsRef = ProviderRef<GoogleCredentials>;
String _$facebookCredentialsHash() =>
    r'2a7dbf6d9c453f78799e8b1eac36c4810fbbbedd';

/// See also [facebookCredentials].
@ProviderFor(facebookCredentials)
final facebookCredentialsProvider = Provider<FacebookCredentials>.internal(
  facebookCredentials,
  name: r'facebookCredentialsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$facebookCredentialsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FacebookCredentialsRef = ProviderRef<FacebookCredentials>;
String _$authRepositoryHash() => r'c4ca4464d7464de6d8ebc4bd4ebfb1df5e8e5d9f';

/// Firebase since ADR 0009 phase 4: the Firebase ID token is the session, and the user
/// record is `users/{uid}`.
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$authServiceHash() => r'dae43030a6cf6f4b2d3c066c201f1eff33d0eb1a';

/// The service. The push callback is `ref.read` at call time: it is only needed at
/// sign-out, and a callback keeps `AuthService` free of the notify feature's types.
///
/// Copied from [authService].
@ProviderFor(authService)
final authServiceProvider = Provider<AuthService>.internal(
  authService,
  name: r'authServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthServiceRef = ProviderRef<AuthService>;
String _$authControllerHash() => r'2c28081ccdb61878c116f549aebf72ace840011d';

/// The session, as the UI sees it. `AsyncNotifier` per Week 5 — loading, data, and error
/// are states of one object rather than three booleans.
///
/// `AsyncData(null)` means signed out. That is a real answer, not an empty state: it is
/// what the router redirects on.
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthController = AsyncNotifier<AuthSession?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
