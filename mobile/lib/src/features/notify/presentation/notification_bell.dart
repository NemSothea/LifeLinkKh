import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/inbox_providers.dart';
import 'notifications_screen.dart';

/// The bell on Home's app bar, with the unread count on it. Nine and over reads "9+":
/// the number is a nudge to look, not a figure anyone needs exactly.
class NotificationBell extends ConsumerWidget {
    const NotificationBell({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final unread = ref.watch(unreadNotificationCountProvider);
        return IconButton(
            key: const Key('notification-bell'),
            tooltip: unread == 0
                ? l10n.notificationsBellTooltip
                : l10n.notificationsUnreadLabel(unread),
            onPressed: () => context.push(NotificationsScreen.path),
            icon: Badge(
                key: const Key('notification-badge'),
                isLabelVisible: unread > 0,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: Icon(unread > 0 ? Icons.notifications : Icons.notifications_none),
            ),
        );
    }
}
