import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../error/failure.dart';
import '../theme/app_theme.dart';

/// An action that failed — a send, a save, an answer — said next to the button that
/// tried it.
///
/// A bare red line was the old version, on five screens, each styled by hand: no icon,
/// the same words for "no signal" and "the server said no", and nothing a screen reader
/// announced. This is one tinted strip with an icon, marked as a live region so TalkBack
/// and VoiceOver read it the moment it appears.
///
/// Pass the [error] when there is one. A [NetworkFailure] swaps [message] for "no
/// internet connection": the fix for that one is the donor's, not the app's, and saying
/// so stops a second tap into the same dead signal from looking like a second failure.
///
/// No retry button of its own: every caller already has the button that failed right
/// below it, and two ways to do one thing is one too many.
class InlineError extends StatelessWidget {
    const InlineError({required this.message, this.error, super.key});

    final String message;
    final Object? error;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final offline = error is NetworkFailure;

        return Semantics(
            container: true,
            liveRegion: true,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Icon(
                                offline ? Icons.wifi_off : Icons.error_outline,
                                size: 20,
                                color: scheme.onErrorContainer,
                            ),
                            const SizedBox(width: AppTokens.space12),
                            Expanded(
                                child: Text(
                                    offline ? l10n.sectionFailedNetwork : message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onErrorContainer,
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
