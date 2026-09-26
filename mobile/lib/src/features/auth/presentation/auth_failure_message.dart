import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';

/// Turns a [Failure] into localised copy. One `switch` over the sealed type, so adding a
/// variant is a compile error here rather than a silent fallthrough to "something went
/// wrong".
class AuthFailureMessage extends StatelessWidget {
    const AuthFailureMessage({super.key, required this.error});

    /// `Object` because that is what `AsyncError.error` is. A non-[Failure] means a bug
    /// escaped the data layer, and it renders as the generic case rather than crashing.
    final Object error;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        final (IconData icon, String message) = switch (error) {
            NetworkFailure() => (Icons.wifi_off, l10n.signInFailedNetwork),
            UnauthorizedFailure() => (Icons.lock_outline, l10n.signInFailedRejected),
            RateLimitedFailure() => (Icons.timer_outlined, l10n.signInFailedRateLimited),
            ServerFailure() => (Icons.cloud_off, l10n.signInFailedServer),
            // A rejected role and a not-found are both bugs from this screen's point of
            // view: it always asks for DONOR, which is self-service.
            ValidationFailure() || NotFoundFailure() || UnknownFailure() => (
                Icons.error_outline,
                l10n.signInFailedUnknown,
            ),
            _ => (Icons.error_outline, l10n.signInFailedUnknown),
        };

        return Row(
            key: const Key('sign-in-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(icon, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(
                        message,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                    ),
                ),
            ],
        );
    }
}
