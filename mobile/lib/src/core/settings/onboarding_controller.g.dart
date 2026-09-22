// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingStoreHash() => r'9d5a7816061ecd973c2ba75b90c63322fb605269';

/// Overridden in `main.dart` with the `SharedPreferences`-backed store. The default is
/// the forgetful one, so no test has to stub a platform channel to build a screen.
///
/// Copied from [onboardingStore].
@ProviderFor(onboardingStore)
final onboardingStoreProvider = Provider<OnboardingStore>.internal(
  onboardingStore,
  name: r'onboardingStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingStoreRef = ProviderRef<OnboardingStore>;
String _$onboardingControllerHash() =>
    r'f3ec0506434ec7fe778a18d22aa51cfabb3f5135';

/// Whether the intro still has to be shown.
///
/// `keepAlive` because the router reads it inside `redirect`, which runs on every
/// navigation — a provider that disposed between routes would re-read the store each
/// time and, worse, reset to "not seen" mid-session.
///
/// Copied from [OnboardingController].
@ProviderFor(OnboardingController)
final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>.internal(
      OnboardingController.new,
      name: r'onboardingControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onboardingControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingController = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
