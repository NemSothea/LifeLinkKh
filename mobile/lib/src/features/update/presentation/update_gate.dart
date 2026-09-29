import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/links/link_providers.dart';
import '../application/app_update_providers.dart';
import '../domain/app_config.dart';
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
///
/// `config/app` is read at launch and again whenever the app comes back to the
/// foreground, at most once per [refreshInterval] — so a minimum the admin raises on the
/// portal reaches a phone left open in the background without waiting for a cold start.
class UpdateGate extends ConsumerStatefulWidget {
    const UpdateGate({required this.child, this.clock = DateTime.now, super.key});

    final Widget child;

    /// Injectable so a test can step past [refreshInterval] without waiting a minute.
    final DateTime Function() clock;

    /// Resuming is frequent — a phone call, the camera, a glance at a map — and every
    /// check is a document read. A minute keeps a raised minimum prompt without turning
    /// app switching into a stream of reads.
    static const Duration refreshInterval = Duration(minutes: 1);

    @override
    ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
    late final AppLifecycleListener _lifecycle;
    late DateTime _lastChecked;

    @override
    void initState() {
        super.initState();
        _lastChecked = widget.clock();
        _lifecycle = AppLifecycleListener(onResume: _recheck);
    }

    @override
    void dispose() {
        _lifecycle.dispose();
        super.dispose();
    }

    /// Invalidating keeps the last answer on screen while the new read is in flight
    /// (Riverpod carries the previous value through the reload), so nothing flickers.
    void _recheck() {
        final now = widget.clock();
        if (now.difference(_lastChecked) < UpdateGate.refreshInterval) return;
        _lastChecked = now;
        ref.invalidate(appConfigProvider);
    }

    @override
    Widget build(BuildContext context) {
        final child = widget.child;
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

/// The admin's "what's new", in the app's language when written in it.
String? _notesFor(BuildContext context, ReleaseNotes? notes) =>
    notes?.forLanguage(Localizations.localeOf(context).languageCode);

/// Stateful only for the "what's new" fold: the strip stays one line tall until the
/// user asks for the notes, so it never pushes the screen under it far down.
class _UpdateAvailableStrip extends ConsumerStatefulWidget {
    const _UpdateAvailableStrip({required this.update});

    final UpdateAvailable update;

    @override
    ConsumerState<_UpdateAvailableStrip> createState() => _UpdateAvailableStripState();
}

class _UpdateAvailableStripState extends ConsumerState<_UpdateAvailableStrip> {
    bool _expanded = false;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final update = widget.update;
        final name = update.versionName;
        final notes = _notesFor(context, update.releaseNotes);
        final message = Text(
            name == null ? l10n.updateAvailable : l10n.updateAvailableVersion(name),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
        );

        return Material(
            key: const Key('update-available'),
            color: scheme.secondaryContainer,
            // Owns the status-bar inset while it shows, like `OfflineBanner`'s strip.
            child: SafeArea(
                bottom: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Row(
                        children: [
                            Icon(Icons.system_update, size: 18, color: scheme.onSecondaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                                child: notes == null
                                    ? message
                                    : Semantics(
                                        button: true,
                                        expanded: _expanded,
                                        hint: l10n.updateWhatsNew,
                                        child: InkWell(
                                            key: const Key('update-whats-new'),
                                            onTap: () => setState(() => _expanded = !_expanded),
                                            child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Row(
                                                    children: [
                                                        Flexible(child: message),
                                                        Icon(
                                                            _expanded
                                                                ? Icons.expand_less
                                                                : Icons.expand_more,
                                                            size: 18,
                                                            color: scheme.onSecondaryContainer,
                                                        ),
                                                    ],
                                                ),
                                            ),
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
                            if (notes != null && _expanded)
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(26, 0, 8, 8),
                                    child: Text(
                                        notes,
                                        key: const Key('update-notes'),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                            color: scheme.onSecondaryContainer,
                                        ),
                                    ),
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
        final notes = _notesFor(context, widget.update.releaseNotes);

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
                                if (notes != null) ...[
                                    const SizedBox(height: 24),
                                    Container(
                                        key: const Key('update-required-notes'),
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    l10n.updateWhatsNew,
                                                    style: theme.textTheme.titleSmall,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(notes, style: theme.textTheme.bodyMedium),
                                            ],
                                        ),
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
