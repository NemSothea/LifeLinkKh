import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/retryable_failure.dart';
import '../../donor/application/donor_providers.dart';
import '../application/donation_providers.dart';
import '../../donor/domain/donor_profile.dart';
import '../domain/donation.dart';

/// `GET /donations/me` — `DONATION-history` prototype: an impact number first, the
/// list of individual donations underneath. `FR-08`'s user story is about a donor
/// feeling their impact, which a plain list does not answer on its own.
class DonationHistoryScreen extends ConsumerWidget {
    const DonationHistoryScreen({super.key});

    static const String path = '/donor/donations';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final donations = ref.watch(myDonationsControllerProvider);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.donationHistoryTitle)),
            body: SafeArea(
                child: RefreshIndicator(
                    // Both, because the screen shows both: the list, and the "you can give
                    // again on…" line that comes from the donor profile. Refreshing only
                    // the list right after a hospital confirms shows the new donation
                    // under "you can donate again now" — seen in the 2026-09-25 rehearsal.
                    onRefresh: () => Future.wait([
                        ref.refresh(myDonationsControllerProvider.future),
                        ref.refresh(donorProfileControllerProvider.future),
                    ]),
                    child: switch (donations) {
                        AsyncValue(isLoading: true, hasValue: false) => const Center(
                            child: CircularProgressIndicator(key: Key('donation-history-loading')),
                        ),
                        // A `ListView`, not a `Center`: `RefreshIndicator` drives the
                        // gesture off its child's scroll notifications, so wrapping a
                        // non-scrollable in one makes pull-to-refresh silently dead —
                        // in the exact state where pulling to retry is the obvious move.
                        // `AlwaysScrollableScrollPhysics` keeps the gesture alive even
                        // when the content is shorter than the viewport.
                        AsyncValue(hasError: true) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                                const SizedBox(height: 48),
                                RetryableFailure(
                                    key: const Key('donation-history-failed'),
                                    message: l10n.donationHistoryFailed,
                                    onRetry: () =>
                                        ref.invalidate(myDonationsControllerProvider),
                                ),
                            ],
                        ),
                        AsyncValue(hasValue: true, value: final list) => _body(
                            context,
                            ref,
                            l10n,
                            list ?? const [],
                        ),
                        _ => const SizedBox.shrink(),
                    },
                ),
            ),
        );
    }

    Widget _body(
        BuildContext context,
        WidgetRef ref,
        AppLocalizations l10n,
        List<Donation> donations,
    ) {
        return ListView(
            key: const Key('donation-history-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
                _ImpactCount(count: donations.length),
                // The screen's whole subject is the 56-day cycle, and until now it never
                // said where in that cycle this donor was — the countdown lived only on
                // the home tab. A history is also a "when can I do this again".
                _CycleLine(
                    profile: ref.watch(donorProfileControllerProvider).valueOrNull,
                    donations: donations.length,
                ),
                const SizedBox(height: 24),
                if (donations.isEmpty)
                    Card(
                        key: const Key('donation-history-empty'),
                        margin: const EdgeInsets.only(top: 8),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                            child: Column(
                                children: [
                                    Icon(
                                        Icons.volunteer_activism_outlined,
                                        size: 36,
                                        color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                        l10n.donationHistoryEmpty,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                ],
                            ),
                        ),
                    )
                else
                    for (final donation in donations) ...[
                        _DonationRow(donation: donation),
                        const Divider(),
                    ],
            ],
        );
    }
}

/// The emotional half of `FR-08`. A raw count, not a "lives saved" multiplier — the
/// PRD makes no clinical claim about units per patient, and inventing one is a promise
/// nobody can back. Three real donations reads as three real donations.
class _ImpactCount extends StatelessWidget {
    const _ImpactCount({required this.count});

    final int count;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;

        return Center(
            child: Column(
                children: [
                    Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                            '$count',
                            key: const Key('donation-history-count'),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        l10n.donationHistoryImpact(count),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                    ),
                ],
            ),
        );
    }
}

class _DonationRow extends StatelessWidget {
    const _DonationRow({required this.donation});

    final Donation donation;

    @override
    Widget build(BuildContext context) {
        final languageCode = Localizations.localeOf(context).languageCode;

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        DateFormat.yMMMd(languageCode).format(donation.donatedOn),
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (donation.hospitalName != null)
                        Text(
                            switch (donation.hospitalDistrictLabel(languageCode)) {
                                final String district => '${donation.hospitalName} · $district',
                                null => donation.hospitalName!,
                            },
                            style: Theme.of(context).textTheme.bodyMedium,
                        ),
                ],
            ),
        );
    }
}


/// Reach, and the next date this donor can add to it.
///
/// The multiplier is the same claim the intro makes and the same one transfusion practice
/// makes: a unit is separated into red cells, plasma and platelets, so one donation can
/// reach up to three patients. Written as "up to", because it is a ceiling, not a count of
/// people who were actually helped — this app cannot know that and must not imply it.
class _CycleLine extends StatelessWidget {
    const _CycleLine({required this.profile, required this.donations});

    final DonorProfile? profile;
    final int donations;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final eligibility = profile?.eligibility;

        final next = eligibility == null
            ? null
            : eligibility.isEligible
                ? l10n.donationHistoryEligibleNow
                : eligibility.eligibleOn != null
                    ? l10n.donationHistoryEligibleOn(
                        DateFormat.yMMMMd(Localizations.localeOf(context).toString())
                            .format(eligibility.eligibleOn!),
                    )
                    : null;

        final muted = theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
        );

        return Column(
            children: [
                // Nothing donated yet means no reach to state, and inventing "up to 0
                // patients" would be a worse first impression than saying nothing.
                if (donations > 0)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            l10n.donationHistoryReach(donations * 3),
                            key: const Key('donation-history-reach'),
                            textAlign: TextAlign.center,
                            style: muted,
                        ),
                    ),
                if (next != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            next,
                            key: const Key('donation-history-cycle'),
                            textAlign: TextAlign.center,
                            style: muted,
                        ),
                    ),
            ],
        );
    }
}
