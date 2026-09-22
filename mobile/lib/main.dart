import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/network/auth_token_gateway.dart';
import 'src/core/settings/locale_controller.dart';
import 'src/core/settings/onboarding_controller.dart';
import 'src/core/settings/preferences_locale_store.dart';
import 'src/core/settings/preferences_onboarding_store.dart';
import 'src/features/auth/application/auth_providers.dart';

/// Composition root, and the only place that knows both `core/` and the auth feature.
///
/// No `firebase_options.dart`: Android reads `android/app/google-services.json` through
/// the `google-services` Gradle plugin, and iOS (DEC-006, build-only) reads
/// `ios/Runner/GoogleService-Info.plist` the same way — both plugins discover their config
/// file directly. Generating a Dart options file would put the same values in a third
/// place and require the FlutterFire CLI in CI for no gain.
Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Awaited before `runApp`: `FirebaseAuth.instance` is touched by the first provider
    // read, and reaching it before this completes throws.
    await Firebase.initializeApp();

    // Awaited too, and for a related reason: `LocaleStore.read()` is synchronous so the
    // first frame already paints in the chosen language. That only works if the backing
    // store is loaded before `runApp`.
    final preferences = await SharedPreferences.getInstance();

    runApp(
        ProviderScope(
            overrides: [
                // The seam declared in `core/network/`. Its default is null — an
                // unauthenticated Dio — and this is the one line that turns it on, so a
                // widget test gets a plain client without stubbing Firebase.
                authTokenGatewayProvider.overrideWith(
                    (ref) => ref.watch(authServiceProvider),
                ),
                // Same shape: the default store forgets the language at exit, and this
                // is the one line that makes the choice survive a restart.
                localeStoreProvider.overrideWithValue(
                    PreferencesLocaleStore(preferences),
                ),
                // And the intro flag, for the same reason: the default store forgets it
                // at exit, which would show the carousel on every single launch.
                onboardingStoreProvider.overrideWithValue(
                    PreferencesOnboardingStore(preferences),
                ),
            ],
            child: const LifeLinkApp(),
        ),
    );
}
