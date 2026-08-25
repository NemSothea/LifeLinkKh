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
String _$telegramAuthRepositoryHash() =>
    r'facbe2665f9511404c92bce3271aeb852a955609';

/// Same unintercepted client as `authRepository` — neither Telegram call carries a
/// bearer token either.
///
/// Copied from [telegramAuthRepository].
@ProviderFor(telegramAuthRepository)
final telegramAuthRepositoryProvider =
    Provider<TelegramAuthRepository>.internal(
      telegramAuthRepository,
      name: r'telegramAuthRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$telegramAuthRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TelegramAuthRepositoryRef = ProviderRef<TelegramAuthRepository>;
String _$authServiceHash() => r'5f0450a363fc79eb708f4409e47d869b3434c34c';

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
String _$authControllerHash() => r'09d34f91dd3a015d554deb1cf3dd97085b94ff18';

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
String _$telegramStartControllerHash() =>
    r'aac88b91dfc4e1451df4b68193f55d408483b0ec';

/// The Telegram sheet's own state (FR-AUTH-004) — the deep link and session token, not
/// a session. Deliberately **not** `keepAlive`: this is scoped to one sheet's lifetime,
/// and a stale challenge from a closed, reopened sheet must not survive to be reused.
///
/// Copied from [TelegramStartController].
@ProviderFor(TelegramStartController)
final telegramStartControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TelegramStartController,
      TelegramStartSession?
    >.internal(
      TelegramStartController.new,
      name: r'telegramStartControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$telegramStartControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TelegramStartController =
    AutoDisposeAsyncNotifier<TelegramStartSession?>;
String _$telegramVerifyControllerHash() =>
    r'214bd77f922073af15e72d24c23b45ced03d2c73';

/// The code-entry step's own state (FR-AUTH-004) — separate from
/// `TelegramStartController` because a wrong code should not throw away the deep link
/// already fetched, and separate from `AuthController` for the reason documented on
/// `AuthController.applyTelegramSession`.
///
/// Copied from [TelegramVerifyController].
@ProviderFor(TelegramVerifyController)
final telegramVerifyControllerProvider =
    AutoDisposeAsyncNotifierProvider<TelegramVerifyController, void>.internal(
      TelegramVerifyController.new,
      name: r'telegramVerifyControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$telegramVerifyControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TelegramVerifyController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
