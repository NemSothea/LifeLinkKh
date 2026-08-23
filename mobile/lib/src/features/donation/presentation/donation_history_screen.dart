import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/donation_providers.dart';
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
                    onRefresh: () => ref.refresh(myDonationsControllerProvider.future),
                    child: switch (donations) {
                        AsyncValue(isLoading: true, hasValue: false) => const Center(
                            child: CircularProgressIndicator(key: Key('donation-history-loading')),
                        ),
                        AsyncValue(hasError: true) => Center(
                            child: Text(
                                l10n.donationHistoryFailed,
                                key: const Key('donation-history-failed'),
                            ),
                        ),
                        AsyncValue(hasValue: true, value: final list) => _body(
                            context,
                            l10n,
                            list ?? const [],
                        ),
                        _ => const SizedBox.shrink(),
                    },
                ),
            ),
        );
    }

    Widget _body(BuildContext context, AppLocalizations l10n, List<Donation> donations) {
        return ListView(
            key: const Key('donation-history-list'),
            padding: const EdgeInsets.all(24),
            children: [
                _ImpactCount(count: donations.length),
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
