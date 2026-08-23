import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_role.dart';
import '../../donation/presentation/donation_history_screen.dart';
import '../../request/presentation/requester_home_tab.dart';
import 'donor_home_tab.dart';
import 'me_tab.dart';

/// Root shell for a signed-in session. `GLOBAL-home-dashboard` prototype: branch once,
/// at the root, on `users.role` — not a role check inside every screen — and reuse one
/// shell with a different tab set, rather than two separate shell widgets.
///
/// `HOSPITAL`/`ADMIN` never reach this shell: the server refuses those roles at mobile
/// self-service sign-up (`TM-AUTH-001` E1), so any role this app has not seen gets the
/// donor tab set, the safer of the two defaults.
///
/// Reachable only when a session exists; the router redirects otherwise, which is also
/// why `role` is read without a loading/error branch — by the time this widget builds,
/// the redirect has already established that a session is present.
class HomeScreen extends ConsumerStatefulWidget {
    const HomeScreen({super.key});

    /// Owned by the screen, not by the router, so a route string appears once in the app.
    static const String path = '/';

    @override
    ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
    int _index = 0;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final role = ref.watch(authControllerProvider).valueOrNull?.user.role;
        final isRequester = role == UserRole.requester;

        final tabs = isRequester
            ? const [RequesterHomeTab(), MeTab()]
            : const [DonorHomeTab(), DonationHistoryScreen(), MeTab()];

        // Guards a stale index surviving a role change mid-session (sign-out/sign-in as
        // the other role reuses this widget rather than remounting it).
        if (_index >= tabs.length) {
            _index = 0;
        }

        return Scaffold(
            body: IndexedStack(index: _index, children: tabs),
            bottomNavigationBar: NavigationBar(
                key: const Key('dashboard-nav'),
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() => _index = value),
                destinations: isRequester
                    ? [
                        NavigationDestination(
                            key: const Key('dashboard-tab-home'),
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: const Icon(Icons.home),
                            label: l10n.dashboardTabHome,
                        ),
                        NavigationDestination(
                            key: const Key('dashboard-tab-me'),
                            icon: const Icon(Icons.person_outline),
                            selectedIcon: const Icon(Icons.person),
                            label: l10n.dashboardTabMe,
                        ),
                    ]
                    : [
                        NavigationDestination(
                            key: const Key('dashboard-tab-home'),
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: const Icon(Icons.home),
                            label: l10n.dashboardTabHome,
                        ),
                        NavigationDestination(
                            key: const Key('dashboard-tab-history'),
                            icon: const Icon(Icons.volunteer_activism_outlined),
                            selectedIcon: const Icon(Icons.volunteer_activism),
                            label: l10n.dashboardTabHistory,
                        ),
                        NavigationDestination(
                            key: const Key('dashboard-tab-me'),
                            icon: const Icon(Icons.person_outline),
                            selectedIcon: const Icon(Icons.person),
                            label: l10n.dashboardTabMe,
                        ),
                    ],
            ),
        );
    }
}
