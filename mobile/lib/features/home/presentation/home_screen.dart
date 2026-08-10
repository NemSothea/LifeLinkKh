import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/health_repository.dart';

/// M2 stub home screen: app name in the active locale, plus the live health result.
/// No features, no auth.
class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final health = ref.watch(healthStatusProvider);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
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
                                data: (status) => Text(
                                    '${l10n.apiStatusUp} ($status)',
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
