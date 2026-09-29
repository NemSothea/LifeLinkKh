import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Drawn in place of a widget that threw while building, in release builds
/// (`installCrashHandlers`). A bug, not a network problem, so there is no retry: the
/// same build would throw the same way. The way out is back, or a restart.
///
/// Has to survive being drawn almost anywhere — including above `MaterialApp`, where
/// there is no theme, no localisations and no text direction. Each of those falls back
/// rather than throwing, because an error widget that throws is an infinite loop.
class ScreenFailure extends StatelessWidget {
    const ScreenFailure({super.key});

    @override
    Widget build(BuildContext context) {
        final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Directionality(
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            child: Material(
                color: scheme.surface,
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTokens.space32),
                        child: Column(
                            key: const Key('screen-failure'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(Icons.healing_outlined, size: 48, color: scheme.primary),
                                const SizedBox(height: AppTokens.space16),
                                Text(
                                    l10n?.screenFailedTitle ?? 'Something went wrong on this screen',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                    ),
                                ),
                                const SizedBox(height: AppTokens.space8),
                                Text(
                                    l10n?.screenFailedBody ??
                                        'Go back and try again. If it keeps happening, '
                                            'close the app and open it again.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
