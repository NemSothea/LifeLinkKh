import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../donation/presentation/donation_history_screen.dart';
import 'home_tab.dart';
import 'me_tab.dart';

/// Root shell for a signed-in session. `GLOBAL-home-dashboard` prototype: one shell, one
/// tab set — Home, History, Me — for every account the app can hold.
///
/// It used to branch on `users.role` and give a `REQUESTER` a two-tab shell. Nothing
/// assigns that role (`AuthService.DEFAULT_ROLE` is `DONOR`, and no endpoint or screen
/// changes it), so the branch had one live arm and the requester's own screen was
/// unreachable. Removed 2026-09-24; `HomeTab` carries the reasoning.
///
/// `HOSPITAL`/`ADMIN` never reach this shell either way: the server refuses those roles at
/// mobile self-service sign-up (`TM-AUTH-001` E1).
///
/// Reachable only when a session exists; the router redirects otherwise.
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
        // One shell for everyone. The tab set used to branch on `users.role == REQUESTER`,
        // a value nothing in the product ever assigns — see HomeTab's own note. The branch
        // therefore had exactly one live arm and hid the requester's screen from the people
        // it was written for.
        const tabs = [HomeTab(), DonationHistoryScreen(), MeTab()];

        return Scaffold(
            body: IndexedStack(index: _index, children: tabs),
            bottomNavigationBar: NavigationBar(
                key: const Key('dashboard-nav'),
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() => _index = value),
                destinations: [
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
