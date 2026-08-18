import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/home/presentation/home_screen.dart';

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

            if (!signedIn && !atSignIn) return SignInScreen.path;
            if (signedIn && atSignIn) return HomeScreen.path;
            return null;
        },
        routes: [
            GoRoute(
                path: SignInScreen.path,
                builder: (context, state) => const SignInScreen(),
            ),
            GoRoute(
                path: HomeScreen.path,
                builder: (context, state) => const HomeScreen(),
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
