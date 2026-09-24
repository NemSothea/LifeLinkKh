import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// "What to expect when you donate" — `BRIEF-DONATION-001`. Static, no API: before, at the
/// centre, after, and next time.
///
/// Written for the first-time donor, whose biggest barrier is not knowing what happens once
/// they walk in. The snack, water and thank-you gift are here because they are part of that
/// answer — and framed as recovery care and thanks, never as a reward: `prd.md` rules out
/// rewards, and voluntary donation is unpaid by definition. The gift line says "many
/// centres", not "you will get": what is handed out differs by centre and by campaign, and a
/// promise the app cannot keep is worse than no promise.
class DonationGuideScreen extends StatelessWidget {
    const DonationGuideScreen({super.key});

    static const String path = '/donate/what-to-expect';

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.donateGuideTitle)),
            body: SafeArea(
                child: ListView(
                    key: const Key('donation-guide'),
                    padding: const EdgeInsets.all(16),
                    children: [
                        Text(l10n.donateGuideIntro, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        _Section(
                            icon: Icons.restaurant_outlined,
                            title: l10n.donateGuideBeforeTitle,
                            items: [
                                l10n.donateGuideBeforeMeal,
                                l10n.donateGuideBeforeSleep,
                                l10n.donateGuideBeforeId,
                            ],
                        ),
                        _Section(
                            icon: Icons.local_hospital_outlined,
                            title: l10n.donateGuideDuringTitle,
                            items: [
                                l10n.donateGuideDuringCheck,
                                l10n.donateGuideDuringTime,
                            ],
                        ),
                        _Section(
                            key: const Key('donation-guide-after'),
                            icon: Icons.volunteer_activism_outlined,
                            title: l10n.donateGuideAfterTitle,
                            items: [
                                l10n.donateGuideAfterRest,
                                l10n.donateGuideAfterSnack,
                                l10n.donateGuideAfterGift,
                                l10n.donateGuideAfterCare,
                            ],
                        ),
                        _Section(
                            icon: Icons.event_available_outlined,
                            title: l10n.donateGuideNextTitle,
                            items: [l10n.donateGuideNextCooldown],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            l10n.donateGuideVoluntary,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

class _Section extends StatelessWidget {
    const _Section({
        required this.icon,
        required this.title,
        required this.items,
        super.key,
    });

    final IconData icon;
    final String title;
    final List<String> items;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);

        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            children: [
                                Icon(icon, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(title, style: theme.textTheme.titleMedium),
                                ),
                            ],
                        ),
                        const SizedBox(height: 8),
                        for (final item in items)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        const Padding(
                                            padding: EdgeInsets.only(top: 2, right: 10),
                                            child: Icon(Icons.check, size: 18),
                                        ),
                                        Expanded(
                                            child: Text(item, style: theme.textTheme.bodyMedium),
                                        ),
                                    ],
                                ),
                            ),
                    ],
                ),
            ),
        );
    }
}
