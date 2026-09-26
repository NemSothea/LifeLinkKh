import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/config/env.dart';
import 'src/core/network/auth_token_gateway.dart';
import 'src/core/settings/locale_controller.dart';
import 'src/core/settings/onboarding_controller.dart';
import 'src/core/settings/preferences_locale_store.dart';
import 'src/core/settings/preferences_onboarding_store.dart';
import 'src/features/auth/application/auth_providers.dart';
import 'src/features/notify/application/push_providers.dart';
import 'src/features/notify/application/push_session_sync.dart';
import 'src/features/notify/data/firebase_push_arrivals.dart';

/// Composition root, and the only place that knows both `core/` and the auth feature.
///
/// No `firebase_options.dart`: Android reads `android/app/google-services.json` through
/// the `google-services` Gradle plugin, and iOS (DEC-006, build-only) reads
/// `ios/Runner/GoogleService-Info.plist` the same way — both plugins discover their config
/// file directly. Generating a Dart options file would put the same values in a third
/// place and require the FlutterFire CLI in CI for no gain.
Future<void> main() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();

    // Keeps the native launch screen up past the first frame, until `LifeLinkApp` sees
    // the session restore resolve — otherwise a signed-in donor watches the splash hand
    // off to Flutter's own badge and then to Home, three screens for one launch.
    // The timer is the backstop: a keystore read that never returns must not leave the
    // app stuck behind a picture. Past it, `SignInScreen`'s in-Flutter badge takes over,
    // which is the same mark on the same colour.
    FlutterNativeSplash.preserve(widgetsBinding: binding);
    Timer(const Duration(seconds: 4), FlutterNativeSplash.remove);

    // Awaited before `runApp`: `FirebaseAuth.instance` is touched by the first provider
    // read, and reaching it before this completes throws.
    await Firebase.initializeApp();

    // ADR 0009: point Firestore at a local emulator when FIRESTORE_EMULATOR is set. Before
    // any read — the SDK refuses to switch once the first query has gone to the real project.
    final emulator = Env.firestoreEmulator;
    if (emulator != null) {
        FirebaseFirestore.instance.useFirestoreEmulator(emulator.host, emulator.port);
    }

    // Awaited too, and for a related reason: `LocaleStore.read()` is synchronous so the
    // first frame already paints in the chosen language. That only works if the backing
    // store is loaded before `runApp`.
    final preferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
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
            // Pushes that land while the app runs. Default empty, so widget tests
            // never reach a Firebase platform channel.
            pushArrivalsProvider.overrideWith((ref) => firebasePushArrivals()),
        ],
    );

    // Started here and nowhere else, so no widget test that restores a session reaches
    // Firebase through it. `keepAlive`, so this one read keeps it running for the app's
    // lifetime. After the first frame, not before: read eagerly it pulls the keystore
    // read and the FCM permission and token calls in front of startup, measured at about
    // a second of extra launch time on the API 36 emulator. It loses nothing by waiting —
    // a session already restored by then is picked up as restored.
    binding.addPostFrameCallback((_) => container.read(pushSessionSyncProvider));

    runApp(
        UncontrolledProviderScope(
            container: container,
            child: const LifeLinkApp(),
        ),
    );
}
