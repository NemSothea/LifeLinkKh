import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/config/env.dart';
import 'src/core/error/crash_handling.dart';
import 'src/core/firebase/firestore_providers.dart';
import 'src/core/settings/locale_controller.dart';
import 'src/core/widgets/launch_splash.dart';
import 'src/core/settings/onboarding_controller.dart';
import 'src/core/settings/preferences_locale_store.dart';
import 'src/core/settings/preferences_onboarding_store.dart';
import 'src/features/notify/application/push_providers.dart';
import 'src/features/avatar/application/avatar_providers.dart';
import 'src/features/avatar/data/preferences_avatar_store.dart';
import 'src/features/notify/application/push_session_sync.dart';
import 'src/features/notify/application/inbox_providers.dart';
import 'src/features/notify/data/firebase_push_arrivals.dart';
import 'src/features/notify/data/firestore_notification_inbox_repository.dart';
import 'src/features/update/application/app_update_providers.dart';
import 'src/features/update/data/firestore_app_config_repository.dart';
import 'src/features/update/data/preferences_update_dismissal_store.dart';

/// Composition root: the one place that swaps the test-friendly defaults for the real
/// platform stores and streams.
///
/// No `firebase_options.dart`: Android reads `android/app/google-services.json` through
/// the `google-services` Gradle plugin, and iOS (DEC-006, build-only) reads
/// `ios/Runner/GoogleService-Info.plist` the same way — both plugins discover their config
/// file directly. Generating a Dart options file would put the same values in a third
/// place and require the FlutterFire CLI in CI for no gain.
Future<void> main() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();

    // First, so an error anywhere below — Firebase init included — is caught by it.
    installCrashHandlers();

    // The splash, drawn before anything is awaited. Everything below — Firebase, the
    // preferences file — runs before the real app can be built, and until this existed
    // the whole of it sat behind the native launch screen: a still picture with no sign
    // of life. The real app replaces this tree below, and its first screen is the same
    // `LaunchSplash` until the session is restored, so the spinner never jumps.
    runApp(const LaunchSplashApp());

    // Awaited before the real app: `FirebaseAuth.instance` is touched by the first
    // provider read, and reaching it before this completes throws.
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
            // The default store forgets the language at exit, and this is the one
            // line that makes the choice survive a restart.
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
            // `config/app`, for the update check and the privacy link. Default knows
            // nothing, so no widget test that boots the app makes this read.
            appConfigRepositoryProvider.overrideWith(
                (ref) => FirestoreAppConfigRepository(ref.watch(firestoreProvider)),
            ),
            // "Later" on a new-version notice, kept across restarts.
            updateDismissalStoreProvider.overrideWithValue(
                PreferencesUpdateDismissalStore(preferences),
            ),
            // The bell's inbox. Default always empty, so no widget test that builds
            // Home opens a Firestore listener.
            notificationInboxRepositoryProvider.overrideWith(
                (ref) => FirestoreNotificationInboxRepository(ref.watch(firestoreProvider)),
            ),
            // The avatar the user picked on the Me tab.
            avatarStoreProvider.overrideWithValue(PreferencesAvatarStore(preferences)),
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
