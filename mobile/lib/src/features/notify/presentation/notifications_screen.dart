import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/relative_time.dart';
import '../../auth/application/auth_providers.dart';
import '../../match/presentation/match_detail_screen.dart';
import '../../request/presentation/request_detail_screen.dart';
import '../application/inbox_providers.dart';
import '../domain/app_notification.dart';

/// The bell's list: every push the portal sent this person, newest first, whether or
/// not the notification itself was seen. Opening it marks everything read.
class NotificationsScreen extends ConsumerStatefulWidget {
    const NotificationsScreen({super.key});

    static const String path = '/notifications';

    @override
    ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
    /// What was unread when the screen opened. Kept for the screen's lifetime, so the dot
    /// on each new row stays up while the person reads it rather than vanishing the moment
    /// the list is marked read.
    final Set<String> _newOnOpen = {};

    @override
    void initState() {
        super.initState();
        // Entries that arrive while the screen is open are marked read as they land —
        // the person is looking right at them.
        ref.listenManual<AsyncValue<List<AppNotification>>>(
            inboxProvider,
            (_, next) => _markSeen(next.valueOrNull),
            fireImmediately: true,
        );
    }

    void _markSeen(List<AppNotification>? entries) {
        if (entries == null) return;
        final marked = ref.read(inboxReadMarksProvider);
        final fresh = entries.where((e) => e.isUnread && !marked.contains(e.id));
        if (fresh.isEmpty) return;
        setState(() => _newOnOpen.addAll(fresh.map((e) => e.id)));
        // After this frame: a provider cannot be changed while the tree is building.
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.read(inboxReadMarksProvider.notifier).markAllRead();
        });
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final inbox = ref.watch(inboxProvider);
        return Scaffold(
            appBar: AppBar(title: Text(l10n.notificationsTitle)),
            body: SafeArea(
                child: switch (inbox) {
                    AsyncValue(hasValue: true, value: final List<AppNotification> entries)
                        when entries.isEmpty =>
                        _Message(
                            icon: Icons.notifications_none,
                            title: l10n.notificationsEmptyTitle,
                            body: l10n.notificationsEmptyBody,
                        ),
                    AsyncValue(hasValue: true, value: final List<AppNotification> entries) =>
                        ListView.separated(
                            key: const Key('notifications-list'),
                            padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) => _NotificationTile(
                                entry: entries[i],
                                highlighted: _newOnOpen.contains(entries[i].id),
                                onTap: () => _open(entries[i]),
                            ),
                        ),
                    AsyncValue(hasError: true) => _Message(
                        icon: Icons.cloud_off,
                        title: l10n.notificationsLoadFailed,
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                },
            ),
        );
    }

    /// The screen the entry is about — the same places a tap on the push itself opens.
    /// A donor alert goes to the match, whose id is the request's and the donor's.
    void _open(AppNotification entry) {
        final requestId = entry.requestId;
        final uid = ref.read(authControllerProvider).valueOrNull?.user.id;
        if (requestId == null || uid == null) return;
        context.push(
            entry.isRequestAlert
                ? MatchDetailScreen.routeFor('${requestId}_$uid')
                : RequestDetailScreen.routeFor(requestId),
        );
    }
}

class _NotificationTile extends StatelessWidget {
    const _NotificationTile({
        required this.entry,
        required this.highlighted,
        required this.onTap,
    });

    final AppNotification entry;

    /// Unread when the screen opened: a dot, and a tinted row.
    final bool highlighted;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return ListTile(
            key: Key('notification-${entry.id}'),
            onTap: entry.requestId == null ? null : onTap,
            tileColor: highlighted ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space16,
                vertical: AppTokens.space4,
            ),
            leading: CircleAvatar(
                backgroundColor:
                    entry.isRequestAlert ? scheme.primary : scheme.surfaceContainerHighest,
                foregroundColor:
                    entry.isRequestAlert ? scheme.onPrimary : scheme.onSurfaceVariant,
                child: Icon(entry.isRequestAlert ? Icons.bloodtype : Icons.assignment_outlined),
            ),
            title: Text(
                entry.title,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                ),
            ),
            subtitle: Padding(
                padding: const EdgeInsets.only(top: AppTokens.space4),
                child: Text(entry.body),
            ),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    Text(
                        formatRelativeTime(context, entry.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                        ),
                    ),
                    if (highlighted) ...[
                        const SizedBox(height: AppTokens.space8),
                        Container(
                            key: Key('notification-unread-${entry.id}'),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                            ),
                        ),
                    ],
                ],
            ),
        );
    }
}

class _Message extends StatelessWidget {
    const _Message({required this.icon, required this.title, this.body});

    final IconData icon;
    final String title;
    final String? body;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(AppTokens.space32),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(icon, size: 48, color: scheme.onSurfaceVariant),
                        const SizedBox(height: AppTokens.space16),
                        Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                        ),
                        if (body != null) ...[
                            const SizedBox(height: AppTokens.space8),
                            Text(
                                body!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                ),
                            ),
                        ],
                    ],
                ),
            ),
        );
    }
}
