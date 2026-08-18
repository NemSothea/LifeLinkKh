import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
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
