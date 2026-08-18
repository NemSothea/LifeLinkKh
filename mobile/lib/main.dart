import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/network/auth_token_gateway.dart';
import 'src/features/auth/application/auth_providers.dart';

/// Composition root, and the only place that knows both `core/` and the auth feature.
///
/// No `firebase_options.dart`: this build ships Android only, where `initializeApp` reads
/// `android/app/google-services.json` through the `google-services` Gradle plugin.
/// Generating a Dart options file would put the same values in two places and require the
/// FlutterFire CLI in CI for no gain. Add it when iOS arrives — which is not in this
/// build (root `CLAUDE.md` §4: Play Store internal testing at M7).
Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Awaited before `runApp`: `FirebaseAuth.instance` is touched by the first provider
    // read, and reaching it before this completes throws.
    await Firebase.initializeApp();

    runApp(
        ProviderScope(
            overrides: [
                // The seam declared in `core/network/`. Its default is null — an
                // unauthenticated Dio — and this is the one line that turns it on, so a
                // widget test gets a plain client without stubbing Firebase.
                authTokenGatewayProvider.overrideWith(
                    (ref) => ref.watch(authServiceProvider),
                ),
            ],
            child: const LifeLinkApp(),
        ),
    );
}
