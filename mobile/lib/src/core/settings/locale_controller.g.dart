// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localeStoreHash() => r'd53afb6342e141a09fb6f893d9a839ada20a2673';

/// Overridden in `main.dart` with the `SharedPreferences`-backed store. The default is
/// deliberately the forgetful one, so no test has to stub a platform channel to build a
/// screen.
///
/// Copied from [localeStore].
@ProviderFor(localeStore)
final localeStoreProvider = Provider<LocaleStore>.internal(
  localeStore,
  name: r'localeStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localeStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocaleStoreRef = ProviderRef<LocaleStore>;
String _$localeControllerHash() => r'7bc88544b61cfa67978d4ea613983de4bc803d5d';

/// The app's language, and the only thing that decides it.
///
/// `FR-GLOBAL-001`'s mobile half. Khmer is the default — the users are Cambodian
/// (`docs/po/prd.md` section 5), and the web portal's `routing.ts` says the same with
/// `defaultLocale: 'km'`. What was missing until now was the other half of that
/// sentence: a way for someone whose Khmer is weak to say so. `MaterialApp.locale` was
/// pinned to `Locale('km')` with no override anywhere, which meant an English speaker
/// could not read a single screen of this app.
///
/// Device locale is deliberately *not* consulted. Most phones in the pilot are set to
/// English regardless of what their owner reads most comfortably, which is exactly the
/// resolution this pin was added to defeat.
///
/// Copied from [LocaleController].
@ProviderFor(LocaleController)
final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>.internal(
      LocaleController.new,
      name: r'localeControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localeControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocaleController = Notifier<Locale>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
