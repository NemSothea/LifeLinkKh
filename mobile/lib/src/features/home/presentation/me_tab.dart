import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_role.dart';
import '../../donor/presentation/donor_profile_screen.dart';
import '../../request/presentation/request_form_screen.dart';

/// The third tab of every shell — `GLOBAL-home-dashboard` prototype: "profile edit,
/// language toggle, and sign-out. Not a settings labyrinth — three items."
///
/// The language toggle is not here yet — `FR-GLOBAL-001` shipped on the web portal
/// first; the mobile side is tracked separately. This tab is the seam it lands in.
class MeTab extends ConsumerWidget {
    const MeTab({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final user = ref.watch(authControllerProvider).valueOrNull?.user;
        final role = user?.role;
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
                        if (role == UserRole.donor)
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
                                        // A donor whose relative needs blood is the most likely
                                        // requester in the pilot (RequestController) — the donor
                                        // shell's Home tab has no "request blood" button, so it
                                        // lives here instead of being lost.
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
                        if (role == UserRole.donor) const SizedBox(height: 16),
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
