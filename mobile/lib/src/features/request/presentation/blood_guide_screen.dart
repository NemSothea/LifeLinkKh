import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/guide_section.dart';

/// "How getting blood works" — for the family, not the donor. DEC-019.
///
/// About three-quarters of Cambodian blood is replacement donation: the hospital asks the
/// family to bring donors, and a relative of *any* blood type counts, because the blood bank
/// issues the patient's type from tested stock. Before this screen the app only ever
/// searched for a stranger with a compatible type, so a family whose relatives are the
/// "wrong" type was never told they could help. It also says blood is free by national
/// policy and never to pay a broker, and warns against a close relative's blood going
/// straight to the patient (transfusion-associated GVHD).
///
/// Static and informational, like `DonationGuideScreen`; the footer says the hospital's
/// blood bank has the final word. Sources: `docs/po/research/2026-09-cambodia-donation-reality.md`.
class BloodGuideScreen extends StatelessWidget {
    const BloodGuideScreen({super.key});

    static const String path = '/request/how-blood-works';

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.bloodGuideTitle)),
            body: SafeArea(
                child: ListView(
                    key: const Key('blood-guide'),
                    padding: const EdgeInsets.all(AppTokens.space16),
                    children: [
                        Text(l10n.bloodGuideIntro, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppTokens.space16),
                        GuideSection(
                            key: const Key('blood-guide-any-type'),
                            icon: Icons.bloodtype_outlined,
                            title: l10n.bloodGuideAnyTypeTitle,
                            items: [
                                l10n.bloodGuideAnyTypeDonate,
                                l10n.bloodGuideAnyTypeStock,
                                l10n.bloodGuideAnyTypeAsk,
                            ],
                        ),
                        GuideSection(
                            key: const Key('blood-guide-free'),
                            icon: Icons.money_off_outlined,
                            title: l10n.bloodGuideFreeTitle,
                            items: [l10n.bloodGuideFreeFee, l10n.bloodGuideFreeNeverPay],
                        ),
                        GuideSection(
                            icon: Icons.family_restroom_outlined,
                            title: l10n.bloodGuideRelativeTitle,
                            items: [l10n.bloodGuideRelativeBody],
                        ),
                        GuideSection(
                            icon: Icons.notifications_active_outlined,
                            title: l10n.bloodGuideAppTitle,
                            items: [l10n.bloodGuideAppReview, l10n.bloodGuideAppDonors],
                        ),
                        const SizedBox(height: AppTokens.space8),
                        Text(
                            l10n.bloodGuideSource,
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
