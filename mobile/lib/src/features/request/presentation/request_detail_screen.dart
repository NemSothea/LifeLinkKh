import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/time/relative_time.dart';
import '../application/request_providers.dart';
import '../domain/blood_request.dart';
import '../domain/request_status.dart';
import 'urgency_badge.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/retryable_failure.dart';

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
    Failure? _cancelFailure;

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
            _cancelFailure = null;
        });
        final result = await ref
            .read(myRequestsControllerProvider.notifier)
            .cancel(widget.requestId);
        if (!mounted) return;
        setState(() {
            _isCancelling = false;
            _cancelFailure = switch (result) {
                Failed(:final failure) => failure,
                _ => null,
            };
        });
        if (_cancelFailure != null) HapticFeedback.heavyImpact();
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
                    // Retryable in place: a bare sentence left backing out of the screen as
                    // the only way to try again.
                    error: (error, _) => Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: RetryableFailure(
                                key: const Key('request-detail-failed'),
                                message: l10n.requestDetailFailed,
                                error: error,
                                onRetry: () =>
                                    ref.invalidate(requestDetailProvider(widget.requestId)),
                            ),
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
            RequestStatus.pending => l10n.requestStatusPending,
            RequestStatus.open => l10n.requestStatusOpen,
            RequestStatus.rejected => l10n.requestStatusRejected,
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
                    // Before approval (DEC-015) the counts are all zero by design, and
                    // "0 donors alerted" under a request reads as "nobody could help".
                    // Say what is actually happening instead; the counts return once an
                    // admin has opened it to donors.
                    switch (request.status) {
                        RequestStatus.pending => _ReviewCard(
                            key: const Key('request-pending'),
                            icon: Icons.hourglass_top,
                            title: l10n.requestPendingTitle,
                            body: Text(l10n.requestPendingBody),
                        ),
                        RequestStatus.rejected => _ReviewCard(
                            key: const Key('request-rejected'),
                            icon: Icons.block,
                            title: l10n.requestRejectedTitle,
                            isError: true,
                            body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        l10n.requestRejectedReasonLabel,
                                        style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        switch (request.rejectReason?.trim()) {
                                            final String reason when reason.isNotEmpty => reason,
                                            _ => l10n.requestRejectedNoReason,
                                        },
                                        key: const Key('request-reject-reason'),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(l10n.requestRejectedHint),
                                ],
                            ),
                        ),
                        _ => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                        ),
                    },
                    const SizedBox(height: 8),
                    // Same change as `MatchDetailScreen`: a requester refreshing this
                    // screen is asking "how long has nobody answered", which an absolute
                    // timestamp makes them work out for themselves.
                    Text(
                        '${l10n.requestPostedLabel} · '
                        '${formatRelativeTime(context, request.createdAt)}',
                        key: const Key('request-age'),
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    // Only once donors can actually answer — while pending no one has been
                    // asked yet, and a rejected request never will be.
                    if (request.status == RequestStatus.open && request.acceptedCount == 0)
                        Text(l10n.requestWaitingForResponders, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    if (_cancelFailure != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InlineError(
                                key: const Key('request-cancel-failed'),
                                message: l10n.requestCancelFailed,
                                error: _cancelFailure,
                            ),
                        ),
                    if (request.status.isCancellable)
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
/// and colour, not by reading a plain grey label. `open` and `pending` use
/// `Urgency.routine`'s neutral treatment — waiting for review is not bad news;
/// `rejected`/`cancelled`/`expired` reuse the error role `UrgencyBadge` already
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
            RequestStatus.pending ||
            RequestStatus.open => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
            RequestStatus.fulfilled => isDark
                ? (const Color(0xFF1B4332), const Color(0xFF8FD9B6))
                : (const Color(0xFFDCF5E7), const Color(0xFF1B6E43)),
            RequestStatus.rejected ||
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

/// The panel that replaces the donor counts while a request is under admin review or
/// after it was refused (DEC-015). A card, not a line of text, because it is the one
/// thing on the screen the requester needs to read: why nothing has happened yet, or
/// why nothing will.
class _ReviewCard extends StatelessWidget {
    const _ReviewCard({
        required this.icon,
        required this.title,
        required this.body,
        this.isError = false,
        super.key,
    });

    final IconData icon;
    final String title;
    final Widget body;
    final bool isError;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        final background = isError ? scheme.errorContainer : scheme.secondaryContainer;
        final foreground = isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;
        return Card(
            color: background,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: DefaultTextStyle.merge(
                    style: TextStyle(color: foreground),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    Icon(icon, color: foreground),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(color: foreground),
                                        ),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            body,
                        ],
                    ),
                ),
            ),
        );
    }
}
