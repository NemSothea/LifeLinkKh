import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/relative_time.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/retryable_failure.dart';
import '../../request/domain/blood_request.dart';
import '../../request/presentation/urgency_badge.dart';
import '../application/match_providers.dart';
import '../domain/match.dart';
import '../domain/match_response_type.dart';
import '../../../core/widgets/money_notice.dart';
import '../../report/presentation/report_request_sheet.dart';

/// A single match — request detail, then accept/decline, then (on accept) the
/// requester's contact. `NOTIFY-donor-alert` screen 2 and 3 in the prototype.
///
/// Reads the match out of `myMatchesControllerProvider`'s already-loaded list
/// rather than issuing its own fetch: `GET /matches/me` already returned every
/// field this screen needs, and a second call could only return a stale copy of
/// the same row.
///
/// In-app messaging (prototype screen 3's fallback for an unverified phone
/// number) is not built: it has no FR and no endpoint (`contract.md`'s "Open —
/// blocks M4" list). This screen shows the phone number with the unverified
/// caveat and stops there — a real, working phone-only path rather than a button
/// with nothing behind it.
class MatchDetailScreen extends ConsumerStatefulWidget {
    const MatchDetailScreen({required this.matchId, super.key});

    final String matchId;

    static const String routePath = '/inbox/:matchId';

    static String routeFor(String matchId) => '/inbox/$matchId';

    @override
    ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
    bool _isResponding = false;
    Failure? _respondFailure;

    Future<void> _report(String requestId) async {
        final l10n = AppLocalizations.of(context)!;
        final sent = await showReportRequestSheet(context, requestId: requestId);
        if (sent == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportSent)));
        }
    }

    Future<void> _respond(MatchResponseType response) async {
        // A firmer tick for yes than for no: accepting is the commitment. Not awaited —
        // the buzz is feedback, and the answer must not wait on the platform channel.
        if (response == MatchResponseType.accepted) {
            HapticFeedback.mediumImpact();
        } else {
            HapticFeedback.selectionClick();
        }
        setState(() {
            _isResponding = true;
            _respondFailure = null;
        });
        final result = await ref
            .read(myMatchesControllerProvider.notifier)
            .respond(widget.matchId, response);
        if (!mounted) return;
        setState(() {
            _isResponding = false;
            _respondFailure = switch (result) {
                Failed(:final failure) => failure,
                _ => null,
            };
        });
        if (_respondFailure != null) HapticFeedback.heavyImpact();
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final inbox = ref.watch(myMatchesControllerProvider);
        final matches = inbox.valueOrNull ?? const [];
        Match? match;
        for (final candidate in matches) {
            if (candidate.matchId == widget.matchId) {
                match = candidate;
                break;
            }
        }

        return Scaffold(
            appBar: AppBar(
                title: Text(l10n.inboxTitle),
                actions: [
                    // DEC-019: asked for money, a fake request, harassment. To the admin only.
                    if (match != null)
                        IconButton(
                            key: const Key('match-report'),
                            tooltip: l10n.reportCta,
                            icon: const Icon(Icons.outlined_flag),
                            onPressed: () => _report(match!.request.id),
                        ),
                ],
            ),
            body: SafeArea(
                // Opened from a tapped notification on a cold start, the inbox is still
                // loading — that used to render "could not load" for the first second.
                child: match != null
                    ? _body(context, l10n, match)
                    : inbox.isLoading && !inbox.hasValue
                    ? const Center(child: CircularProgressIndicator(key: Key('match-loading')))
                    : Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: RetryableFailure(
                                key: const Key('match-not-found'),
                                message: l10n.requestDetailFailed,
                                error: inbox.error,
                                isRetrying: inbox.isLoading,
                                onRetry: () => ref.invalidate(myMatchesControllerProvider),
                            ),
                        ),
                    ),
            ),
        );
    }

    Widget _body(BuildContext context, AppLocalizations l10n, Match match) {
        final languageCode = Localizations.localeOf(context).languageCode;
        final request = match.request;

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
                                    // Every request a donor is alerted to was approved by an
                                    // admin first (DEC-015); DEC-019 makes that visible, since
                                    // "is this real?" is the donor's first question.
                                    Wrap(
                                        spacing: AppTokens.space8,
                                        runSpacing: AppTokens.space8,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                            UrgencyBadge(
                                                key: const Key('match-urgency'),
                                                urgency: request.urgency,
                                            ),
                                            const _ReviewedBadge(),
                                        ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                        request.patientBloodType.wireValue,
                                        style: Theme.of(context).textTheme.displaySmall,
                                    ),
                                    Text('${l10n.requestUnitsLabel}: ${request.unitsNeeded}'),
                                    const Divider(height: 32),
                                    Text(
                                        request.hospitalName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                        switch ((
                                            request.hospitalDistrictLabel(languageCode),
                                            request.distanceKm,
                                        )) {
                                            (final String district, final double km) =>
                                                '$district · ~$km km',
                                            (final String district, null) => district,
                                            (null, final double km) => '~$km km',
                                            (null, null) => '',
                                        },
                                    ),
                                    const SizedBox(height: 12),
                                    // Age, not wall-clock time. `NOTIFY-donor-alert`
                                    // screen 2 asks for "Requested · 14 minutes ago"
                                    // and this screen shipped "2 Sep 2026 06:13" —
                                    // which is the one fact a donor deciding whether to
                                    // leave the house has to do arithmetic on.
                                    Row(
                                        children: [
                                            Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                                '${l10n.requestPostedLabel} · '
                                                '${formatRelativeTime(context, request.createdAt)}',
                                                key: const Key('match-request-age'),
                                                style: Theme.of(context).textTheme.bodyMedium
                                                    ?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                        l10n.inboxYourBloodTypeCompatible(match.myBloodType.wireValue),
                        key: const Key('match-compatible'),
                    ),
                    const SizedBox(height: 32),
                    if (match.rejectedReason != null && match.response == null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                                l10n.matchRejectedAfterQueue,
                                key: const Key('match-rejected-after-queue'),
                            ),
                        ),
                    if (match.isPending) _pendingBadge(context, l10n),
                    if (match.awaitsAnswer) ..._respondActions(l10n, match),
                    // Opened from an old push or a deep link after the request closed.
                    if (match.response == null && !match.awaitsAnswer && !match.isPending)
                        Text(l10n.matchRequestClosed, key: const Key('match-request-closed')),
                    if (match.response == MatchResponseType.accepted)
                        _acceptedResult(context, l10n, request),
                    if (match.response == MatchResponseType.declined)
                        Text(l10n.matchDeclinedTitle, key: const Key('match-declined')),
                ],
            ),
        );
    }

    /// The donor answered, the answer is on the device, the hospital has not heard
    /// it yet. Saying "not sent yet" is the honest version — a spinner would imply
    /// the app is still trying, and silence would imply the hospital knows.
    Widget _pendingBadge(BuildContext context, AppLocalizations l10n) {
        final scheme = Theme.of(context).colorScheme;
        return Container(
            key: const Key('match-pending'),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Icon(Icons.cloud_off, size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                                l10n.matchPendingBadge,
                                style: Theme.of(context).textTheme.labelLarge,
                            ),
                        ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        l10n.matchPendingExplanation,
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
            ),
        );
    }

    /// Accept and decline each ask once more, in a sheet that repeats what is being
    /// answered. A tap on a notification lands here in a hurry, and an accidental
    /// accept sends a family a donor's promise that nobody made.
    Future<void> _confirm(MatchResponseType response, Match match) async {
        final confirmed = await showModalBottomSheet<bool>(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            isScrollControlled: true,
            builder: (sheetContext) => _RespondSheet(match: match, response: response),
        );
        if (confirmed == true && mounted) await _respond(response);
    }

    List<Widget> _respondActions(AppLocalizations l10n, Match match) => [
        const MoneyNotice(key: Key('match-money-notice')),
        const SizedBox(height: 16),
        if (_respondFailure != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InlineError(
                    key: const Key('match-respond-failed'),
                    message: l10n.matchRespondFailed,
                    error: _respondFailure,
                ),
            ),
        Row(
            children: [
                Expanded(
                    child: OutlinedButton(
                        key: const Key('match-decline'),
                        onPressed: _isResponding
                            ? null
                            : () => _confirm(MatchResponseType.declined, match),
                        child: Text(l10n.matchDeclineCta),
                    ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    flex: 2,
                    child: FilledButton(
                        key: const Key('match-accept'),
                        style: _acceptStyle(context),
                        onPressed: _isResponding
                            ? null
                            : () => _confirm(MatchResponseType.accepted, match),
                        child: Text(l10n.matchAcceptCta),
                    ),
                ),
            ],
        ),
    ];

    Widget _acceptedResult(BuildContext context, AppLocalizations l10n, BloodRequest request) {
        final contact = request.requesterContact;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    l10n.matchAcceptedTitle,
                    key: const Key('match-accepted'),
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (contact != null) ...[
                    Text(l10n.matchContactTitle, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SelectableText('${contact.displayName} · ${contact.phone}'),
                    const SizedBox(height: 8),
                    // The moment a stranger's number is on screen is when money could come up.
                    const MoneyNotice(key: Key('match-accepted-money-notice')),
                    const SizedBox(height: 8),
                    Text(
                        l10n.matchContactUnverified,
                        key: const Key('match-contact-unverified'),
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                        key: const Key('match-copy-phone'),
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: contact.phone));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.matchPhoneCopied)),
                            );
                        },
                        label: Text(l10n.matchCopyPhoneCta),
                    ),
                ],
            ],
        );
    }
}

/// Green, per `NOTIFY-donor-alert` screen 2: accepting is the good outcome, and the
/// app's red already means "blood needed".
ButtonStyle _acceptStyle(BuildContext context) {
    final tokens = AppTokens.of(context);
    return FilledButton.styleFrom(
        backgroundColor: tokens.onSuccess,
        foregroundColor: tokens.success,
    );
}

/// The confirm step: what is being answered, then the answer, then a way out.
class _RespondSheet extends StatefulWidget {
    const _RespondSheet({required this.match, required this.response});

    final Match match;
    final MatchResponseType response;

    @override
    State<_RespondSheet> createState() => _RespondSheetState();
}

class _RespondSheetState extends State<_RespondSheet> {
    /// Which self-check lines the donor ticked (DEC-019). Only ever read to warn.
    final Set<int> _ticked = {};

    Match get match => widget.match;
    MatchResponseType get response => widget.response;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final request = match.request;
        final accepting = response == MatchResponseType.accepted;
        final distance = request.distanceKm;

        // DEC-019: the deferrals a donor can check at home, so nobody travels to the centre
        // only to be turned away. A warning, never a gate: the centre decides, and a donor who
        // ticks something by mistake must still be able to accept.
        final selfCheck = [
            l10n.matchCheckUnderweight,
            l10n.donateGuideWaitFever,
            l10n.donateGuideWaitAntibiotics,
            l10n.donateGuideWaitDengue,
            l10n.donateGuideWaitTattoo,
            l10n.donateGuideWaitPregnant,
            l10n.donateGuideWaitSurgery,
        ];

        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.space24,
                0,
                AppTokens.space24,
                AppTokens.space24,
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Row(
                        children: [
                            CircleAvatar(
                                radius: 28,
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                child: Text(
                                    request.patientBloodType.wireValue,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                            ),
                            const SizedBox(width: AppTokens.space16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            request.hospitalName,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                            ),
                                        ),
                                        const SizedBox(height: AppTokens.space4),
                                        Wrap(
                                            spacing: AppTokens.space8,
                                            runSpacing: AppTokens.space4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                                UrgencyBadge(urgency: request.urgency),
                                                if (distance != null)
                                                    Text('~$distance km', style: theme.textTheme.bodySmall),
                                                Text(
                                                    formatRelativeTime(context, request.createdAt),
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                        color: scheme.onSurfaceVariant,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Text(
                        l10n.inboxYourBloodTypeCompatible(match.myBloodType.wireValue),
                        style: theme.textTheme.bodyMedium,
                    ),
                    if (accepting) ...[
                        const SizedBox(height: AppTokens.space16),
                        Text(
                            l10n.matchCheckTitle,
                            key: const Key('match-self-check'),
                            style: theme.textTheme.titleSmall,
                        ),
                        for (var i = 0; i < selfCheck.length; i++)
                            CheckboxListTile(
                                key: Key('match-self-check-$i'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: _ticked.contains(i),
                                title: Text(selfCheck[i]),
                                onChanged: (on) => setState(
                                    () => on == true ? _ticked.add(i) : _ticked.remove(i),
                                ),
                            ),
                        if (_ticked.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: AppTokens.space8),
                                child: _SelfCheckWarning(text: l10n.matchCheckWarning),
                            ),
                    ],
                    const SizedBox(height: AppTokens.space24),
                    if (accepting)
                        FilledButton.icon(
                            key: const Key('match-accept-confirm'),
                            style: _acceptStyle(context),
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.check),
                            label: Text(l10n.matchAcceptCta),
                        )
                    else
                        FilledButton.tonalIcon(
                            key: const Key('match-decline-confirm'),
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.close),
                            label: Text(l10n.matchDeclineCta),
                        ),
                    const SizedBox(height: AppTokens.space8),
                    TextButton(
                        key: const Key('match-respond-cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    ),
                ],
            ),
        );
    }
}

/// "Checked by a LifeLink admin", next to the urgency badge.
class _ReviewedBadge extends StatelessWidget {
    const _ReviewedBadge();

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final tokens = AppTokens.of(context);
        return DecoratedBox(
            key: const Key('match-reviewed'),
            decoration: BoxDecoration(
                color: tokens.success,
                borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space8 + 2,
                    vertical: AppTokens.space4,
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(Icons.verified_user_outlined, size: 14, color: tokens.onSuccess),
                        const SizedBox(width: AppTokens.space4),
                        Flexible(
                            child: Text(
                                l10n.matchReviewedBadge,
                                style: TextStyle(
                                    color: tokens.onSuccess,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// Amber, not red: ticking a line is honest, not a failure. Announced as a live region.
class _SelfCheckWarning extends StatelessWidget {
    const _SelfCheckWarning({required this.text});

    final String text;

    @override
    Widget build(BuildContext context) {
        final tokens = AppTokens.of(context);
        return Semantics(
            container: true,
            liveRegion: true,
            child: DecoratedBox(
                key: const Key('match-self-check-warning'),
                decoration: BoxDecoration(
                    color: tokens.urgencyMedium,
                    borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Icon(Icons.info_outline, size: 20, color: tokens.onUrgencyMedium),
                            const SizedBox(width: AppTokens.space12),
                            Expanded(
                                child: Text(text, style: TextStyle(color: tokens.onUrgencyMedium)),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
