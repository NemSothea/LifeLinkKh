import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/settings/locale_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../donor/presentation/donor_profile_screen.dart';
import '../../request/presentation/request_form_screen.dart';

/// The third tab of every shell — `GLOBAL-home-dashboard` prototype: "profile edit,
/// language toggle, and sign-out. Not a settings labyrinth — three items."
///
/// The language toggle is the mobile half of `FR-GLOBAL-001`, which shipped on the web
/// portal first (`LanguageSwitcher`). It is the last item before sign-out on purpose:
/// someone who cannot read the app is hunting for it, and it is the only control here
/// that has to be findable without reading the label above it — hence the flag-free
/// endonyms, ខ្មែរ and English, each written in its own script.
class MeTab extends ConsumerWidget {
    const MeTab({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final user = ref.watch(authControllerProvider).valueOrNull?.user;
        final theme = Theme.of(context);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.dashboardTabMe)),
            body: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                        // A Google account without a name is valid (AuthUser.displayName's
                        // own doc comment) — an empty name shows the icon alone rather than
                        // an empty header line.
                        Row(
                            children: [
                                CircleAvatar(
                                    radius: 28,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Icon(
                                        Icons.person_outline,
                                        color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                ),
                                if (user != null && user.displayName.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Text(
                                            user.displayName,
                                            style: theme.textTheme.titleLarge,
                                            overflow: TextOverflow.ellipsis,
                                        ),
                                    ),
                                ],
                            ],
                        ),
                        const SizedBox(height: 24),
                        // No role gate. The same dead branch that hid the requester's Home
                        // hid these two rows from nobody — every real account is DONOR — and
                        // would have hidden "donor profile" from the one person who needs it
                        // if the role had ever been assigned.
                        Card(
                                margin: EdgeInsets.zero,
                                child: Column(
                                    children: [
                                        ListTile(
                                            key: const Key('me-donor-profile'),
                                            leading: const Icon(Icons.badge_outlined),
                                            title: Text(l10n.donorProfileTitle),
                                            trailing: const Icon(Icons.chevron_right),
                                            onTap: () => context.push(DonorProfileScreen.path),
                                        ),
                                        const Divider(height: 1),
                                        // Duplicated from Home's own button on purpose: Home is
                                        // where someone in a hurry looks, Me is where someone
                                        // hunting through settings looks.
                                        ListTile(
                                            key: const Key('me-request-blood'),
                                            leading: const Icon(Icons.bloodtype_outlined),
                                            title: Text(l10n.requestNewCta),
                                            trailing: const Icon(Icons.chevron_right),
                                            onTap: () => context.push(RequestFormScreen.path),
                                        ),
                                    ],
                                ),
                            ),
                        const SizedBox(height: 16),
                        const _LanguageCard(),
                        const SizedBox(height: 16),
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                key: const Key('sign-out'),
                                leading: const Icon(Icons.logout),
                                title: Text(l10n.signOut),
                                onTap: () =>
                                    ref.read(authControllerProvider.notifier).signOut(),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// The language toggle. Reads the locale that is actually in effect
/// (`Localizations.localeOf`) rather than the controller's own value, so the control
/// can never claim a language the surrounding screen is not already rendering in.
class _LanguageCard extends ConsumerWidget {
    const _LanguageCard();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final active = Localizations.localeOf(context).languageCode;

        return Card(
            margin: EdgeInsets.zero,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            children: [
                                const Icon(Icons.translate),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Text(
                                        l10n.languageLabel,
                                        style: theme.textTheme.titleMedium,
                                    ),
                                ),
                            ],
                        ),
                        const SizedBox(height: 12),
                        // Full width so the two segments split evenly — a content-sized
                        // SegmentedButton makes "English" visibly wider than "ខ្មែរ",
                        // which reads as one option being the recommended one.
                        SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                                key: const Key('me-language'),
                                showSelectedIcon: false,
                                segments: const [
                                    // Endonyms, never translated: the whole point of this
                                    // control is to be usable by someone who cannot read
                                    // the language the app is currently in.
                                    ButtonSegment(value: 'km', label: Text('ខ្មែរ')),
                                    ButtonSegment(value: 'en', label: Text('English')),
                                ],
                                selected: {active},
                                onSelectionChanged: (selection) => ref
                                    .read(localeControllerProvider.notifier)
                                    .select(Locale(selection.first)),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
