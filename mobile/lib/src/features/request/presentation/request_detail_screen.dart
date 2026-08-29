import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../application/request_providers.dart';
import '../domain/blood_request.dart';
import '../domain/request_status.dart';
import 'urgency_badge.dart';

/// A single request — the "waiting for responders" screen from the prototype, reached
/// by `pushReplacement` right after `RequestFormScreen` creates it.
///
/// `distanceKm` and `requesterContact` are always null here: those only appear
/// when the caller is a matched donor, and this screen is only reachable by a
/// request's own creator, never by a donor — a donor answers from their home tab's
/// nearby-requests list instead (`MatchDetailScreen`).
class RequestDetailScreen extends ConsumerStatefulWidget {
    const RequestDetailScreen({required this.requestId, super.key});

    final String requestId;

    static const String routePath = '/requests/:id';

    static String routeFor(String requestId) => '/requests/$requestId';

    @override
    ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
    bool _isCancelling = false;
    bool _cancelFailed = false;

    Future<void> _cancel() async {
        final l10n = AppLocalizations.of(context)!;
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                title: Text(l10n.requestCancelConfirmTitle),
                content: Text(l10n.requestCancelConfirmMessage),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l10n.donorBack),
                    ),
                    FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.requestCancelCta),
                    ),
                ],
            ),
        );
        if (confirmed != true || !mounted) return;

        setState(() {
            _isCancelling = true;
            _cancelFailed = false;
        });
        final result = await ref
            .read(myRequestsControllerProvider.notifier)
            .cancel(widget.requestId);
        if (!mounted) return;
        setState(() {
            _isCancelling = false;
            _cancelFailed = result is Failed<BloodRequest>;
        });
        if (result is Success<BloodRequest>) {
            ref.invalidate(requestDetailProvider(widget.requestId));
        }
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final detail = ref.watch(requestDetailProvider(widget.requestId));

        return Scaffold(
            appBar: AppBar(title: Text(l10n.requestDetailTitle)),
            body: SafeArea(
                child: detail.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(key: Key('request-detail-loading')),
                    ),
                    error: (_, _) => Center(
                        child: Text(
                            l10n.requestDetailFailed,
                            key: const Key('request-detail-failed'),
                        ),
                    ),
                    data: (request) => _body(context, l10n, request),
                ),
            ),
        );
    }

    Widget _body(BuildContext context, AppLocalizations l10n, BloodRequest request) {
        final languageCode = Localizations.localeOf(context).languageCode;

        String statusLabel(RequestStatus status) => switch (status) {
            RequestStatus.open => l10n.requestStatusOpen,
            RequestStatus.fulfilled => l10n.requestStatusFulfilled,
            RequestStatus.cancelled => l10n.requestStatusCancelled,
            RequestStatus.expired => l10n.requestStatusCancelled,
        };

        return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: [
                                            UrgencyBadge(urgency: request.urgency),
                                            const SizedBox(width: 8),
                                            _StatusPill(
                                                key: const Key('request-status'),
                                                status: request.status,
                                                label: statusLabel(request.status),
                                            ),
                                        ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        '${request.patientBloodType.wireValue} · '
                                        '${request.unitsNeeded}',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        switch (request.hospitalDistrictLabel(languageCode)) {
                                            final String district =>
                                                '${request.hospitalName} · $district',
                                            null => request.hospitalName,
                                        },
                                    ),
                                ],
                            ),
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                        l10n.requestAlertedCount(request.alertedCount),
                        key: const Key('request-alerted-count'),
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        l10n.requestAcceptedCount(request.acceptedCount),
                        key: const Key('request-accepted-count'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        DateFormat.yMMMd(languageCode).add_jm().format(request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    if (request.acceptedCount == 0)
                        Text(l10n.requestWaitingForResponders, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    if (_cancelFailed)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                                l10n.requestCancelFailed,
                                key: const Key('request-cancel-failed'),
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                        ),
                    if (request.status == RequestStatus.open)
                        SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                                key: const Key('request-cancel'),
                                onPressed: _isCancelling ? null : _cancel,
                                child: Text(
                                    _isCancelling
                                        ? l10n.requestCancelling
                                        : l10n.requestCancelCta,
                                ),
                            ),
                        ),
                ],
            ),
        );
    }
}

/// A request's own status, color-coded the same way `UrgencyBadge` codes urgency — a
/// requester should be able to tell "fulfilled" (good) from "cancelled" (not) by shape
/// and colour, not by reading a plain grey label. `open` uses `Urgency.routine`'s
/// neutral treatment; `cancelled`/`expired` reuse the error role `UrgencyBadge` already
/// uses for `critical`; `fulfilled` hand-picks a green pair the same way `UrgencyBadge`
/// hand-picks amber for `urgent` — Material 3 has no built-in "success" role either.
class _StatusPill extends StatelessWidget {
    const _StatusPill({required this.status, required this.label, super.key});

    final RequestStatus status;
    final String label;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final (Color background, Color foreground) = switch (status) {
            RequestStatus.open => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
            RequestStatus.fulfilled => isDark
                ? (const Color(0xFF1B4332), const Color(0xFF8FD9B6))
                : (const Color(0xFFDCF5E7), const Color(0xFF1B6E43)),
            RequestStatus.cancelled ||
            RequestStatus.expired => (scheme.errorContainer, scheme.onErrorContainer),
        };

        return DecoratedBox(
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                    label,
                    style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                    ),
                ),
            ),
        );
    }
}
