import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../error/failure.dart';

/// A failed section that can be retried in place.
///
/// A bare error string is a dead end: the only recovery it offers is backing out of the
/// screen, and on a home tab there is nowhere to back out to. Every *form* failure
/// surface in this app (`donor_profile_screen`, `district_dropdown`, `hospital_dropdown`)
/// already pairs its message with `l10n.retry`; the three list surfaces — nearby
/// requests, my requests, donation history — did not, and those are the ones a donor
/// hits on a hospital's bad mobile signal.
///
/// Pass the section's [error] too. A [NetworkFailure] replaces [message] with "no
/// connection": "could not load your requests" on a phone in airplane mode reads as
/// the server losing the donor's data, and the fix — find a signal — is the donor's.
class RetryableFailure extends StatelessWidget {
    const RetryableFailure({
        required this.message,
        required this.onRetry,
        this.error,
        super.key,
    });

    final String message;
    final VoidCallback onRetry;
    final Object? error;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final offline = error is NetworkFailure;

        return Card(
            margin: EdgeInsets.zero,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                    children: [
                        Icon(offline ? Icons.wifi_off : Icons.cloud_off, size: 32, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                            offline ? l10n.sectionFailedNetwork : message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                        ),
                    ],
                ),
            ),
        );
    }
}
