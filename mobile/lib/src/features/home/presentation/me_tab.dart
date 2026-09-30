import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/settings/locale_controller.dart';
import '../../about/application/about_providers.dart';
import '../../about/presentation/about_screen.dart';
import '../../account/presentation/delete_account_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../avatar/application/avatar_providers.dart';
import '../../avatar/presentation/avatar_picker_sheet.dart';
import '../../avatar/presentation/profile_avatar.dart';
import '../../donation/presentation/donation_guide_screen.dart';
import '../../donor/presentation/donor_profile_screen.dart';
import '../../request/presentation/request_form_screen.dart';

/// The third tab of every shell — `GLOBAL-home-dashboard` prototype: "profile edit,
/// language toggle, and sign-out. Not a settings labyrinth — three items." Plus, since
/// DEC-016, "Delete account" below sign-out, which Google Play requires in-app.
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
        final version = ref.watch(appVersionProvider).valueOrNull;

        return Scaffold(
            appBar: AppBar(title: Text(l10n.dashboardTabMe)),
            body: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                        // A Google account without a name is valid (AuthUser.displayName's
                        // own doc comment) — an empty name shows the avatar alone rather than
                        // an empty header line.
                        Row(
                            children: [
                                _AvatarButton(fallbackColor: theme.colorScheme.primaryContainer),
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
                                        const Divider(height: 1),
                                        ListTile(
                                            key: const Key('me-donation-guide'),
                                            leading: const Icon(Icons.volunteer_activism_outlined),
                                            title: Text(l10n.donateGuideCta),
                                            trailing: const Icon(Icons.chevron_right),
                                            onTap: () => context.push(DonationGuideScreen.path),
                                        ),
                                    ],
                                ),
                            ),
                        const SizedBox(height: 16),
                        const _LanguageCard(),
                        const SizedBox(height: 16),
                        // One row, not three: How it works, the privacy policy, who made the
                        // app and its version all live behind it on About — this tab stays
                        // the short list the prototype asks for.
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                key: const Key('me-about'),
                                leading: const Icon(Icons.info_outline),
                                title: Text(l10n.aboutHelpCta),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push(AboutScreen.path),
                            ),
                        ),
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
                        // DEC-016. Last, apart, and in the error colour: the one action on
                        // this tab that cannot be taken back must not sit where a thumb
                        // reaching for sign-out lands. It only opens the confirmation screen.
                        const SizedBox(height: 32),
                        Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                                key: const Key('me-delete-account'),
                                leading: Icon(
                                    Icons.delete_forever_outlined,
                                    color: theme.colorScheme.error,
                                ),
                                title: Text(
                                    l10n.accountDeleteCta,
                                    style: TextStyle(color: theme.colorScheme.error),
                                ),
                                onTap: () => context.push(DeleteAccountScreen.path),
                            ),
                        ),
                        if (version != null) ...[
                            const SizedBox(height: 24),
                            Text(
                                l10n.appVersionLabel(version.version, version.build),
                                key: const Key('me-version'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                ),
                            ),
                        ],
                    ],
                ),
            ),
        );
    }
}

/// The user's generated avatar, with a pencil badge that says it can be changed. Tapping
/// it opens the picker; a pick replaces it on the spot.
class _AvatarButton extends ConsumerWidget {
    const _AvatarButton({required this.fallbackColor});

    /// Only painted for the instant before a session exists, which the Me tab never
    /// really shows — but a blank hole would be worse than a plain disc.
    final Color fallbackColor;

    static const double _radius = 32;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final spec = ref.watch(avatarControllerProvider);
        if (spec == null) {
            return CircleAvatar(radius: _radius, backgroundColor: fallbackColor);
        }

        return Semantics(
            button: true,
            label: l10n.avatarChangeLabel,
            excludeSemantics: true,
            child: InkWell(
                key: const Key('me-avatar'),
                customBorder: const CircleBorder(),
                onTap: () async {
                    final picked = await showAvatarPicker(context, spec);
                    if (picked != null) {
                        await ref.read(avatarControllerProvider.notifier).pick(picked);
                    }
                },
                child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                        ProfileAvatar(spec: spec, radius: _radius),
                        Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: scheme.surface, width: 2),
                                ),
                                child: Icon(Icons.edit, size: 12, color: scheme.onPrimary),
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
