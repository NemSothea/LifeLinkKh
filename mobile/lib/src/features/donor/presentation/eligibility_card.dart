import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/eligibility.dart';

/// The 56-day cooldown, as the server computed it.
///
/// When not yet eligible this shows **both** the day count and the calendar date — an
/// acceptance criterion of `FR-DONOR-001`, because a countdown alone cannot be planned
/// around and a date alone hides how close it is.
///
/// Nothing here computes anything. `daysRemaining` and `eligibleOn` are read from the
/// response; two implementations of the 56-day rule would eventually disagree, and the
/// one on the device is the one that cannot be fixed without a release.
///
/// The eligible state gets a gradient and the theme's own primary colour — this is the
/// one thing a donor opens the app to check, and it is good news, so it gets to look
/// like it. The waiting state stays calm and neutral on purpose: a countdown is not an
/// alert.
class EligibilityCard extends StatelessWidget {
    const EligibilityCard({required this.eligibility, super.key});

    final Eligibility eligibility;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final tokens = AppTokens.of(context);
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
            clipBehavior: Clip.antiAlias,
            child: Container(
                decoration: BoxDecoration(
                    gradient: isEligible
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [tokens.eligible, tokens.eligible.withValues(alpha: 0.78)],
                        )
                        : null,
                    color: isEligible ? null : tokens.cooldown,
                ),
                padding: const EdgeInsets.all(AppTokens.space16 + AppTokens.space4),
                child: Row(
                    children: [
                        Icon(
                            isEligible ? Icons.check_circle_outline : Icons.schedule,
                            size: 32,
                            color: isEligible ? tokens.onEligible : tokens.onCooldown,
                        ),
                        const SizedBox(width: AppTokens.space16),
                        Flexible(
                            child: Text(
                                message,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isEligible ? tokens.onEligible : scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
