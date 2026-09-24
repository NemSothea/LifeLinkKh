import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/settings/onboarding_controller.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/donation/presentation/donation_guide_screen.dart';
import '../features/donation/presentation/donation_history_screen.dart';
import '../features/donor/presentation/donor_profile_screen.dart';
import '../features/donor/presentation/donor_setup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/intro_screen.dart';
import '../features/match/presentation/match_detail_screen.dart';
import '../features/request/presentation/request_detail_screen.dart';
import '../features/request/presentation/request_form_screen.dart';

part 'app_router.g.dart';

/// Declarative route table. go_router is here from M2 because M4 opens a specific request
/// from an FCM notification tap — that is a deep link, and retrofitting one onto
/// hand-rolled navigation is the expensive way to do it.
///
/// A provider rather than a global as of M3: the redirect has to read the session, and the
/// session is a provider. `keepAlive` because a router that is disposed and rebuilt loses
/// the navigation stack.
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
    return GoRouter(
        initialLocation: SignInScreen.path,
        // Re-runs `redirect` when the session changes — on sign-in, on sign-out, and on the
        // terminal 401 that ADR 0007 cannot repair.
        refreshListenable: _AuthListenable(ref),
        redirect: (context, state) {
            final auth = ref.read(authControllerProvider);

            // Still reading the keystore. Staying put avoids a flash of the sign-in screen
            // for a donor who is in fact signed in — which on a push tap is the difference
            // between answering an alert and losing it.
            if (auth.isLoading && !auth.hasValue) return null;

            final signedIn = auth.valueOrNull != null;
            final atSignIn = state.matchedLocation == SignInScreen.path;
            final atIntro = state.matchedLocation == IntroScreen.path;

            // The intro sits *before* sign-in, not after: it exists to answer "why should
            // I?" before the app asks for a Google account. Only a first launch reaches
            // it, and only while signed out — a donor woken by an alert at 03:00 must
            // never be shown a carousel on the way to the request.
            final seenIntro = ref.read(onboardingControllerProvider);
            if (!signedIn && !seenIntro) return atIntro ? null : IntroScreen.path;
            // Seen it, or signed in: the intro is no longer a place this app can be.
            if (atIntro) return signedIn ? HomeScreen.path : SignInScreen.path;

            if (!signedIn && !atSignIn) return SignInScreen.path;
            if (signedIn && atSignIn) return HomeScreen.path;
            return null;
        },
        routes: [
            GoRoute(
                path: IntroScreen.path,
                builder: (context, state) => const IntroScreen(),
            ),
            GoRoute(
                path: SignInScreen.path,
                builder: (context, state) => const SignInScreen(),
            ),
            GoRoute(
                path: HomeScreen.path,
                builder: (context, state) => const HomeScreen(),
            ),
            // Both behind the redirect above: a donor profile belongs to a session.
            GoRoute(
                path: DonorProfileScreen.path,
                builder: (context, state) => const DonorProfileScreen(),
            ),
            GoRoute(
                path: DonorSetupScreen.path,
                builder: (context, state) => const DonorSetupScreen(),
            ),
            // M5 — FR-DONATION-001.
            GoRoute(
                path: DonationHistoryScreen.path,
                builder: (context, state) => const DonationHistoryScreen(),
            ),
            // BRIEF-DONATION-001 — static, but still behind the redirect: every entry
            // point to it is inside the signed-in shell.
            GoRoute(
                path: DonationGuideScreen.path,
                builder: (context, state) => const DonationGuideScreen(),
            ),
            // M4 — FR-REQUEST-001/002, FR-MATCH-001, FR-NOTIFY-001.
            GoRoute(
                path: RequestFormScreen.path,
                builder: (context, state) => const RequestFormScreen(),
            ),
            GoRoute(
                path: RequestDetailScreen.routePath,
                builder: (context, state) => RequestDetailScreen(
                    requestId: state.pathParameters['id']!,
                ),
            ),
            GoRoute(
                path: MatchDetailScreen.routePath,
                builder: (context, state) => MatchDetailScreen(
                    matchId: state.pathParameters['matchId']!,
                ),
            ),
        ],
    );
}

/// Bridges Riverpod to go_router's `Listenable`.
///
/// go_router predates Riverpod in this app's dependency list and only knows how to listen
/// to a `Listenable`; this is the adapter, and it is the whole reason the router is a
/// provider.
class _AuthListenable extends ChangeNotifier {
    _AuthListenable(Ref ref) {
        // Not `fireImmediately`: `redirect` reads the current state itself, and notifying
        // during construction would ask the router to rebuild while it is being built.
        _subscription = ref.listen(
            authControllerProvider,
            (previous, next) => notifyListeners(),
        );
    }

    late final ProviderSubscription<Object?> _subscription;

    @override
    void dispose() {
        _subscription.close();
        super.dispose();
    }
}
