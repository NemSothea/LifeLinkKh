import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../network/connectivity_providers.dart';

/// A strip above every screen while the phone is offline.
///
/// Mounted once, in `MaterialApp.router`'s `builder`, so no screen has to remember it.
/// The tree shape is the same online and offline — the strip collapses to nothing
/// rather than being removed — because swapping [child] in and out of a `Column`
/// would re-parent the router's `Navigator` and throw away the whole back stack.
class OfflineBanner extends ConsumerWidget {
    const OfflineBanner({required this.child, super.key});

    final Widget child;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final offline = ref.watch(isOfflineProvider).valueOrNull ?? false;
        final scheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;

        return Column(
            children: [
                if (offline)
                    Material(
                        key: const Key('offline-banner'),
                        color: scheme.errorContainer,
                        // The strip owns the status-bar inset while it shows; the screen
                        // under it must not pad for it a second time.
                        child: SafeArea(
                            bottom: false,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                    children: [
                                        Icon(Icons.wifi_off, size: 18, color: scheme.onErrorContainer),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                l10n.offlineBanner,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: scheme.onErrorContainer,
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                    )
                else
                    const SizedBox.shrink(),
                Expanded(
                    child: MediaQuery.removePadding(
                        context: context,
                        removeTop: offline,
                        child: child,
                    ),
                ),
            ],
        );
    }
}
