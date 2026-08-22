import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../application/request_providers.dart';
import '../domain/blood_request.dart';
import '../domain/request_status.dart';

/// A single request — the "waiting for responders" screen from the prototype, and
/// also what `MyRequestsScreen` opens into.
///
/// `distanceKm` and `requesterContact` are always null here: those only appear
/// when the caller is a matched donor, and this screen is only reachable by a
/// request's own creator (`MyRequestsScreen`), never by a donor — a donor answers
/// from their inbox instead (`MatchDetailScreen`).
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
                                    const SizedBox(height: 8),
                                    Text(
                                        statusLabel(request.status),
                                        key: const Key('request-status'),
                                        style: Theme.of(context).textTheme.labelLarge,
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
