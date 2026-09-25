import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import 'push_providers.dart';

part 'push_session_sync.g.dart';

/// Keeps this device's FCM registration tied to the session for as long as the app runs.
///
/// Interactive sign-in already registers (`AuthController._signInWith`). Two cases were
/// never covered, and both leave a signed-in user silently receiving nothing:
///
/// - **A restored session.** `users.fcm_token` holds one token per user, so the last
///   device to sign in owns it. Open the same account on a second device and the first
///   stops getting alerts — and reopening the first, still signed in, never took it back.
///   Registering on restore makes "the device in your hand" the one that gets the push.
/// - **A rotated token.** FCM rotates on reinstall, restore or its own schedule.
///   [PushRegistrationService.watchTokenRefreshes] existed for exactly this and nothing
///   ever subscribed to it.
///
/// Activated only by `main.dart`, like `pushArrivalsProvider`: a widget test that restores
/// a session never reaches `FirebaseMessaging` through this.
@Riverpod(keepAlive: true)
void pushSessionSync(PushSessionSyncRef ref) {
    StreamSubscription<String>? refreshes;
    ref.onDispose(() => refreshes?.cancel());

    ref.listen<AsyncValue<AuthSession?>>(
        authControllerProvider,
        (previous, next) {
            final signedIn = next.valueOrNull != null;

            // The keystore read resolving to a session — the same "loading with no value
            // yet" test the router and the splash use. An interactive sign-in's loading
            // state carries the previous (null) value, so it never matches here and is not
            // registered twice.
            final restored = signedIn &&
                (previous == null || (previous.isLoading && !previous.hasValue));
            if (restored) {
                unawaited(ref.read(pushRegistrationServiceProvider).registerThisDevice());
            }

            if (signedIn) {
                refreshes ??= ref.read(pushRegistrationServiceProvider).watchTokenRefreshes();
            } else if (!next.isLoading) {
                // Signed out. The server-side token was cleared on the way out, and a
                // rotation registered now would answer 401 anyway.
                unawaited(refreshes?.cancel());
                refreshes = null;
            }
        },
        fireImmediately: true,
    );
}
