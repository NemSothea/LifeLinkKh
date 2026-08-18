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
String _$authRepositoryHash() => r'5b7dc96a12914892b3b8b136d6d8d5362d4f269c';

/// Built on `signInApiClient` — the Dio **without** the auth interceptor. Renewing a
/// session over the client that repairs sessions is the recursion ADR 0007 warns about.
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
String _$authServiceHash() => r'a2f82777f418b616624dfcbb54fd9c88d7e1dde9';

/// The service, and the [AuthTokenGateway] the HTTP layer holds.
///
/// The two callbacks are `ref.read` at call time on purpose. `fcmTokenRepository` needs
/// the intercepted Dio, which needs this object — reading it eagerly here would be a
/// provider cycle; reading it when sign-out actually happens is not.
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
String _$authControllerHash() => r'96f8b0f59429714e6a33f1a78008e42279032ed2';

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
