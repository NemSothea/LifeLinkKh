import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/guide_section.dart';

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
                        GuideSection(
                            icon: Icons.restaurant_outlined,
                            title: l10n.donateGuideBeforeTitle,
                            items: [
                                l10n.donateGuideBeforeWeight,
                                l10n.donateGuideBeforeMeal,
                                l10n.donateGuideBeforeSleep,
                                l10n.donateGuideBeforeId,
                            ],
                        ),
                        // DEC-019: the temporary deferrals a donor can check at home (WHO 2012),
                        // so nobody travels to the centre only to be turned away. Informational:
                        // the note under the list says the centre decides.
                        GuideSection(
                            key: const Key('donation-guide-wait'),
                            icon: Icons.pause_circle_outline,
                            title: l10n.donateGuideWaitTitle,
                            items: [
                                l10n.donateGuideWaitFever,
                                l10n.donateGuideWaitAntibiotics,
                                l10n.donateGuideWaitDengue,
                                l10n.donateGuideWaitTattoo,
                                l10n.donateGuideWaitPregnant,
                                l10n.donateGuideWaitSurgery,
                                l10n.donateGuideWaitNote,
                            ],
                        ),
                        GuideSection(
                            key: const Key('donation-guide-where'),
                            icon: Icons.place_outlined,
                            title: l10n.donateGuideWhereTitle,
                            items: [l10n.donateGuideWhereNbtc, l10n.donateGuideWhereOther],
                        ),
                        GuideSection(
                            icon: Icons.local_hospital_outlined,
                            title: l10n.donateGuideDuringTitle,
                            items: [
                                l10n.donateGuideDuringCheck,
                                l10n.donateGuideDuringTime,
                            ],
                        ),
                        GuideSection(
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
                        GuideSection(
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
