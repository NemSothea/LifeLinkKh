import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/eligibility.dart';

/// The 56-day cooldown, as the server computed it.
///
/// When not yet eligible this shows **both** the day count and the calendar date — an
/// acceptance criterion of `FR-DONOR-001`, because a countdown alone cannot be planned around
/// and a date alone hides how close it is.
///
/// Nothing here computes anything. `daysRemaining` and `eligibleOn` are read from the
/// response; two implementations of the 56-day rule would eventually disagree, and the one on
/// the device is the one that cannot be fixed without a release.
class EligibilityCard extends StatelessWidget {
    const EligibilityCard({required this.eligibility, super.key});

    final Eligibility eligibility;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final isEligible = eligibility.isEligible;

        final String message;
        if (isEligible) {
            message = l10n.donorEligibleNow;
        } else {
            final eligibleOn = eligibility.eligibleOn;
            message = l10n.donorEligibleIn(
                eligibility.daysRemaining ?? 0,
                eligibleOn == null
                    ? '—'
                    // Localised date format: the Khmer locale renders its own month names.
                    : DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                        .format(eligibleOn),
            );
        }

        return Card(
            key: const Key('eligibility-card'),
            color: isEligible ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    children: [
                        Icon(
                            isEligible ? Icons.check_circle_outline : Icons.schedule,
                            color: isEligible ? scheme.onPrimaryContainer : scheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                            child: Text(
                                message,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isEligible
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurface,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
