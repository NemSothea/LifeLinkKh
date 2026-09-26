import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/links/link_providers.dart';
import '../application/app_update_providers.dart';
import '../domain/app_update.dart';

/// The update notice, over every screen — mounted once in `MaterialApp.router`'s
/// `builder`, beside `OfflineBanner` and for the same reason: no screen has to remember
/// it, and it shows on the sign-in screen too, where a donor on a dead build lands first.
///
/// The tree shape never changes. A required update is an opaque layer stacked over
/// [child], not a replacement for it, and the new-version strip collapses to nothing
/// rather than leaving the `Column` — either swap would re-parent the router's
/// `Navigator` and throw away the back stack. Not a dialog: this sits above the
/// `Navigator`, so there is no route to push one onto.
class UpdateGate extends ConsumerWidget {
    const UpdateGate({required this.child, super.key});

    final Widget child;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        // Loading and error both show nothing: the check must never hold up a launch.
        final update = ref.watch(appUpdateControllerProvider).valueOrNull;
        final available = update is UpdateAvailable ? update : null;
        final required = update is UpdateRequired ? update : null;

        return Stack(
            children: [
                Column(
                    children: [
                        if (available != null)
                            _UpdateAvailableStrip(update: available)
                        else
                            const SizedBox.shrink(),
                        Expanded(
                            child: MediaQuery.removePadding(
                                context: context,
                                removeTop: available != null,
                                // Covered screens stay out of TalkBack's reach, or a
                                // screen-reader user could still walk the app behind
                                // the wall.
                                child: ExcludeSemantics(
                                    excluding: required != null,
                                    child: child,
                                ),
                            ),
                        ),
                    ],
                ),
                if (required != null)
                    Positioned.fill(child: _UpdateRequiredScreen(update: required)),
            ],
        );
    }
}

/// `true` when the browser took the link. Shared by both notices so they open it the
/// same way — always externally, see `UrlLauncherLinkOpener`.
Future<bool> _openDownload(WidgetRef ref, Uri downloadUrl) =>
    ref.read(linkOpenerProvider).open(downloadUrl);

class _UpdateAvailableStrip extends ConsumerWidget {
    const _UpdateAvailableStrip({required this.update});

    final UpdateAvailable update;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final name = update.versionName;

        return Material(
            key: const Key('update-available'),
            color: scheme.secondaryContainer,
            // Owns the status-bar inset while it shows, like `OfflineBanner`'s strip.
            child: SafeArea(
                bottom: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                    child: Row(
                        children: [
                            Icon(Icons.system_update, size: 18, color: scheme.onSecondaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    name == null
                                        ? l10n.updateAvailable
                                        : l10n.updateAvailableVersion(name),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSecondaryContainer,
                                    ),
                                ),
                            ),
                            TextButton(
                                key: const Key('update-later'),
                                onPressed: () =>
                                    ref.read(appUpdateControllerProvider.notifier).dismiss(),
                                child: Text(l10n.updateLater),
                            ),
                            TextButton(
                                key: const Key('update-download'),
                                onPressed: () => _openDownload(ref, update.downloadUrl),
                                child: Text(l10n.updateDownload),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

/// Nothing behind this is reachable: no close button, and it covers the router's whole
/// area. Android's back gesture still goes to the router underneath — there is no route
/// up here for a `PopScope` to hook — which at worst pops a screen the user cannot see.
///
/// Stateful only to remember a failed open. The download link is then shown as
/// selectable text, so a phone with no browser that claims it still has a way out.
class _UpdateRequiredScreen extends ConsumerStatefulWidget {
    const _UpdateRequiredScreen({required this.update});

    final UpdateRequired update;

    @override
    ConsumerState<_UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<_UpdateRequiredScreen> {
    bool _openFailed = false;

    Future<void> _download() async {
        final opened = await _openDownload(ref, widget.update.downloadUrl);
        if (mounted) setState(() => _openFailed = !opened);
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final name = widget.update.versionName;

        return Material(
            key: const Key('update-required'),
            color: theme.colorScheme.surface,
            child: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(
                                    Icons.system_update,
                                    size: 64,
                                    color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                    l10n.updateRequiredTitle,
                                    style: theme.textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                    l10n.updateRequiredBody,
                                    style: theme.textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                ),
                                if (name != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                        l10n.updateNewVersion(name),
                                        style: theme.textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                    ),
                                ],
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                    key: const Key('update-required-download'),
                                    onPressed: _download,
                                    icon: const Icon(Icons.download),
                                    label: Text(l10n.updateDownload),
                                ),
                                if (_openFailed) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                        l10n.updateOpenFailed,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.error,
                                        ),
                                        textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                        widget.update.downloadUrl.toString(),
                                        textAlign: TextAlign.center,
                                    ),
                                ],
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
