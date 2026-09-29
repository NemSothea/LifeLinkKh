import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// An in-app address nothing answers to — an old link, a mistyped deep link, a push
/// payload from a build that had a screen this one does not. go_router's default for
/// this is a bare "Page Not Found" in English with the raw path under it.
///
/// One way out, to Home. The router's redirect still applies on the way, so a signed-out
/// user lands on sign-in instead.
class RouteNotFoundScreen extends StatelessWidget {
    const RouteNotFoundScreen({required this.onGoHome, super.key});

    final VoidCallback onGoHome;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Scaffold(
            key: const Key('route-not-found'),
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTokens.space32),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(Icons.explore_off_outlined, size: 48, color: scheme.primary),
                                const SizedBox(height: AppTokens.space16),
                                Text(
                                    l10n.routeNotFoundTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                    ),
                                ),
                                const SizedBox(height: AppTokens.space24),
                                FilledButton.icon(
                                    key: const Key('route-not-found-home'),
                                    onPressed: onGoHome,
                                    icon: const Icon(Icons.home_outlined),
                                    label: Text(l10n.routeNotFoundAction),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
