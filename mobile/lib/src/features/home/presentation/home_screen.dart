import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../donor/application/donor_providers.dart';
import '../../donor/presentation/donor_profile_screen.dart';
import '../../donor/presentation/donor_setup_screen.dart';
import '../../match/presentation/donor_inbox_screen.dart';
import '../../request/presentation/my_requests_screen.dart';
import '../../request/presentation/request_form_screen.dart';
import '../application/health_providers.dart';

/// Home screen: app name in the active locale, the live health result, and sign-out.
///
/// Still a stub in feature terms — donor registration lands next. Reachable only when a
/// session exists; the router redirects otherwise.
///
/// One feature import, and it points at `application/`. The Week 3 version reached into
/// `data/` for the concrete repository; removing that import is the Week 4 deliverable.
/// The domain entity's fields are read through type inference, which is permitted —
/// `domain/` points inward.
class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    /// Owned by the screen, not by the router, so a route string appears once in the app.
    static const String path = '/';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        // ref.watch, because this is build() and the widget should rebuild when the
        // check resolves.
        final health = ref.watch(healthStatusProvider);

        return Scaffold(
            appBar: AppBar(
                title: Text(l10n.appTitle),
                actions: [
                    IconButton(
                        key: const Key('sign-out'),
                        tooltip: l10n.signOut,
                        icon: const Icon(Icons.logout),
                        // Clears the FCM registration before disposing of the token that
                        // authorises the call — see AuthService.signOut.
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                    ),
                ],
            ),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                l10n.appTitle,
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.homeTagline, textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            const _DonorEntryPoint(),
                            const SizedBox(height: 16),
                            const _RequestEntryPoints(),
                            const SizedBox(height: 32),
                            health.when(
                                loading: () => Text(
                                    l10n.apiStatusChecking,
                                    key: const Key('health-checking'),
                                ),
                                // Every failure — no config, timeout, 500, bad body —
                                // renders one handled state. The cause is never shown.
                                error: (_, _) => Text(
                                    l10n.apiStatusUnreachable,
                                    key: const Key('health-down'),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                    ),
                                ),
                                data: (health) => Text(
                                    '${l10n.apiStatusUp} (${health.status})',
                                    key: const Key('health-up'),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

/// The one thing the home screen does besides the health ping: get a signed-in user to their
/// donor profile, or into setup if they have none.
///
/// Watches the profile rather than routing on `isNewAccount`, because the two can disagree —
/// a donor who abandoned setup on their first run is not a new account any more, and would
/// otherwise never be asked again.
class _DonorEntryPoint extends ConsumerWidget {
    const _DonorEntryPoint();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final profile = ref.watch(donorProfileControllerProvider);

        return switch (profile) {
            AsyncValue(hasValue: true, value: final loaded?) => FilledButton.tonalIcon(
                key: const Key('home-donor-profile'),
                icon: const Icon(Icons.badge_outlined),
                onPressed: () => context.push(DonorProfileScreen.path),
                label: Text('${l10n.donorProfileTitle} · ${loaded.bloodType.wireValue}'),
            ),
            AsyncValue(hasValue: true) => FilledButton.icon(
                key: const Key('home-donor-setup'),
                icon: const Icon(Icons.person_add_alt),
                onPressed: () => context.push(DonorSetupScreen.path),
                label: Text(l10n.donorProfileCta),
            ),
            // A failed profile load must not block the rest of the screen; the profile screen
            // owns the retry.
            _ => const SizedBox.shrink(),
        };
    }
}

/// M4's three entry points. Deliberately not gated on having a donor profile —
/// `RequestController` allows any authenticated user to post a request (a donor
/// whose relative needs blood is the most likely requester in the pilot), and the
/// inbox screen itself handles the no-profile case rather than hiding its button.
class _RequestEntryPoints extends StatelessWidget {
    const _RequestEntryPoints();

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;

        return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
                FilledButton.icon(
                    key: const Key('home-request-new'),
                    icon: const Icon(Icons.bloodtype_outlined),
                    onPressed: () => context.push(RequestFormScreen.path),
                    label: Text(l10n.requestNewCta),
                ),
                OutlinedButton.icon(
                    key: const Key('home-my-requests'),
                    icon: const Icon(Icons.list_alt),
                    onPressed: () => context.push(MyRequestsScreen.path),
                    label: Text(l10n.myRequestsCta),
                ),
                OutlinedButton.icon(
                    key: const Key('home-inbox'),
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(DonorInboxScreen.path),
                    label: Text(l10n.inboxCta),
                ),
            ],
        );
    }
}
