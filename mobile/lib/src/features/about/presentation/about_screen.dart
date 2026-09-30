import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/config/env.dart';
import '../../../core/links/link_providers.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../onboarding/presentation/intro_screen.dart';
import '../application/about_providers.dart';

/// What the app is, who made it, the questions a first-time donor asks, how it works,
/// the privacy policy, and the version installed — the things someone checks before they trust an
/// app with their blood type and their location.
///
/// Reachable signed out (the sign-in footer) as well as from the Me tab: the questions
/// matter most *before* someone has handed over a Google account. Every FAQ answer is a
/// string the app already shows somewhere else, so this screen makes no promise the rest
/// of the app does not already make. The contact address is the one the portal's
/// privacy page gives, so the app and the web never name two different inboxes.
class AboutScreen extends ConsumerWidget {
    const AboutScreen({super.key});

    static const String path = '/about';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final version = ref.watch(appVersionProvider).valueOrNull;

        final faqs = <(String, String, String)>[
            ('faq-alert', l10n.faqAlertQ, l10n.introAlertBody),
            ('faq-eligible', l10n.faqEligibleQ, l10n.introEligibleBody),
            ('faq-location', l10n.faqLocationQ, l10n.donorLocationPrivacy),
            ('faq-money', l10n.faqMoneyQ, l10n.moneyNotice),
            (
                'faq-delete',
                l10n.faqDeleteQ,
                l10n.faqDeleteA(l10n.dashboardTabMe, l10n.accountDeleteCta),
            ),
        ];

        return Scaffold(
            appBar: AppBar(title: Text(l10n.aboutTitle)),
            body: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                        const SizedBox(height: 8),
                        Center(child: BrandBadge(color: theme.colorScheme.primary)),
                        const SizedBox(height: 16),
                        // The same untranslated wordmark as the sign-in screen.
                        Text(
                            'LIFELINK KH',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            l10n.aboutPurpose,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ),
                        const SizedBox(height: 8),
                        // DEC-019: the app never presents itself as the NBTC. Same words as
                        // the portal footer.
                        Text(
                            l10n.aboutDisclaimer,
                            key: const Key('about-disclaimer'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(l10n.aboutMadeByTitle),
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                key: const Key('about-made-by'),
                                leading: const Icon(Icons.groups_outlined),
                                title: Text(l10n.aboutMadeBy),
                            ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(l10n.aboutFaqTitle),
                        Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                                children: [
                                    for (final (i, (key, question, answer)) in faqs.indexed) ...[
                                        if (i > 0) const Divider(height: 1),
                                        ExpansionTile(
                                            key: Key(key),
                                            shape: const Border(),
                                            collapsedShape: const Border(),
                                            title: Text(question),
                                            expandedAlignment: Alignment.centerLeft,
                                            childrenPadding:
                                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            children: [Text(answer)],
                                        ),
                                    ],
                                ],
                            ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(l10n.aboutContactTitle),
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                key: const Key('about-contact'),
                                leading: const Icon(Icons.mail_outline),
                                title: Text(l10n.aboutContactBody),
                                subtitle: Text(
                                    Env.supportEmail,
                                    style: TextStyle(color: theme.colorScheme.primary),
                                ),
                                onTap: () => _email(context, ref, l10n),
                            ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                            margin: EdgeInsets.zero,
                            child: Column(
                                children: [
                                    ListTile(
                                        key: const Key('about-how-it-works'),
                                        leading: const Icon(Icons.slideshow_outlined),
                                        title: Text(l10n.signInHowItWorks),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => context.push(IntroScreen.reviewLocation),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                        key: const Key('about-privacy-policy'),
                                        leading: const Icon(Icons.privacy_tip_outlined),
                                        title: Text(l10n.privacyPolicy),
                                        trailing: const Icon(Icons.open_in_new),
                                        onTap: () => ref
                                            .read(linkOpenerProvider)
                                            .open(ref.read(privacyUriProvider)),
                                    ),
                                ],
                            ),
                        ),
                        if (version != null) ...[
                            const SizedBox(height: 24),
                            Text(
                                l10n.appVersionLabel(version.version, version.build),
                                key: const Key('about-version'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                ),
                            ),
                        ],
                        const SizedBox(height: 16),
                    ],
                ),
            ),
        );
    }
}

/// Opens the mail app on the support address. A phone with no mail app — an emulator,
/// often — gets the address on the clipboard instead, so the tap is never a dead end.
Future<void> _email(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref
        .read(linkOpenerProvider)
        .open(Uri(scheme: 'mailto', path: Env.supportEmail));
    if (opened) return;
    await Clipboard.setData(const ClipboardData(text: Env.supportEmail));
    messenger.showSnackBar(SnackBar(content: Text(l10n.aboutContactCopied)));
}

class _SectionTitle extends StatelessWidget {
    const _SectionTitle(this.text);

    final String text;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                ),
            ),
        );
    }
}
