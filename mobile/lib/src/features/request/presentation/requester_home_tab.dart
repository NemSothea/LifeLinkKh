import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/time/relative_time.dart';
import '../../../core/widgets/retryable_failure.dart';
import '../application/request_providers.dart';
import '../domain/blood_request.dart';
import 'request_detail_screen.dart';
import 'request_form_screen.dart';
import 'urgency_badge.dart';

/// Requester shell's Home tab — `GLOBAL-home-dashboard` prototype: one oversized
/// primary action, because a requester opens this app for exactly one reason, usually
/// in a hospital corridor, and the button must be findable without reading.
class RequesterHomeTab extends ConsumerWidget {
    const RequesterHomeTab({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final requests = ref.watch(myRequestsControllerProvider);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
            body: SafeArea(
                child: RefreshIndicator(
                    onRefresh: () => ref.refresh(myRequestsControllerProvider.future),
                    child: ListView(
                        key: const Key('requester-home-list'),
                        // Without this the pull gesture is dead whenever the
                        // content is shorter than the viewport — which on this
                        // tab is the common case, not the edge case.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                            _RequestBloodButton(
                                label: l10n.requestNewCta,
                                onPressed: () => context.push(RequestFormScreen.path),
                            ),
                            const SizedBox(height: 24),
                            Text(
                                l10n.myRequestsCta,
                                style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            switch (requests) {
                                AsyncValue(isLoading: true, hasValue: false) => const Center(
                                    child: CircularProgressIndicator(
                                        key: Key('requester-home-loading'),
                                    ),
                                ),
                                AsyncValue(hasError: true) => RetryableFailure(
                                    key: const Key('requester-home-failed'),
                                    message: l10n.myRequestsFailed,
                                    onRetry: () =>
                                        ref.invalidate(myRequestsControllerProvider),
                                ),
                                AsyncValue(hasValue: true, value: final list) => _list(
                                    context,
                                    l10n,
                                    list ?? const [],
                                ),
                                _ => const SizedBox.shrink(),
                            },
                        ],
                    ),
                ),
            ),
        );
    }

    Widget _list(BuildContext context, AppLocalizations l10n, List<BloodRequest> requests) {
        if (requests.isEmpty) {
            // Same card treatment as the donor tab's and the history screen's empty
            // states. A bare line of text read as a rendering failure next to the
            // oversized button above it.
            return Card(
                key: const Key('requester-home-empty'),
                margin: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    child: Column(
                        children: [
                            Icon(
                                Icons.inbox_outlined,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                                l10n.myRequestsEmpty,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                    ),
                ),
            );
        }
        return Column(
            key: const Key('requester-home-request-list'),
            children: [
                for (final request in requests) _RequestTile(request: request),
            ],
        );
    }
}

class _RequestBloodButton extends StatelessWidget {
    const _RequestBloodButton({required this.label, required this.onPressed});

    final String label;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                key: const Key('requester-home-request-new'),
                style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                onPressed: onPressed,
                icon: const Icon(Icons.bloodtype, size: 28),
                label: Text(label),
            ),
        );
    }
}

class _RequestTile extends StatelessWidget {
    const _RequestTile({required this.request});

    final BloodRequest request;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
                key: Key('requester-home-request-${request.id}'),
                leading: CircleAvatar(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                        request.patientBloodType.wireValue,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                ),
                title: Text(request.hospitalName, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            UrgencyBadge(urgency: request.urgency),
                            const SizedBox(height: 4),
                            Text(
                                '${l10n.requestAlertedCount(request.alertedCount)} · '
                                '${l10n.requestAcceptedCount(request.acceptedCount)}',
                                style: Theme.of(context).textTheme.bodySmall,
                            ),
                            // "12 alerted · 0 accepted" only means something next to how
                            // long that has been true. Three minutes is patience; forty
                            // is a reason to phone the hospital.
                            Text(
                                formatRelativeTime(context, request.createdAt),
                                key: Key('requester-home-request-${request.id}-age'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                ),
                            ),
                        ],
                    ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RequestDetailScreen.routeFor(request.id)),
            ),
        );
    }
}
