import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/relative_time.dart';
import '../../request/domain/blood_request.dart';
import '../../request/presentation/urgency_badge.dart';
import '../application/match_providers.dart';
import '../domain/match.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';

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
    bool _respondFailed = false;

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
            _respondFailed = false;
        });
        final result = await ref
            .read(myMatchesControllerProvider.notifier)
            .respond(widget.matchId, response);
        if (!mounted) return;
        setState(() {
            _isResponding = false;
            _respondFailed = result is Failed<RespondResult>;
        });
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final matches = ref.watch(myMatchesControllerProvider).valueOrNull ?? const [];
        Match? match;
        for (final candidate in matches) {
            if (candidate.matchId == widget.matchId) {
                match = candidate;
                break;
            }
        }

        return Scaffold(
            appBar: AppBar(title: Text(l10n.inboxTitle)),
            body: SafeArea(
                child: match == null
                    ? Center(
                        child: Text(
                            l10n.requestDetailFailed,
                            key: const Key('match-not-found'),
                        ),
                    )
                    : _body(context, l10n, match),
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
                                    UrgencyBadge(
                                        key: const Key('match-urgency'),
                                        urgency: request.urgency,
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
                    if (match.response == null) ..._respondActions(l10n, match),
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
        if (_respondFailed)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                    l10n.matchRespondFailed,
                    key: const Key('match-respond-failed'),
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
class _RespondSheet extends StatelessWidget {
    const _RespondSheet({required this.match, required this.response});

    final Match match;
    final MatchResponseType response;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final request = match.request;
        final accepting = response == MatchResponseType.accepted;
        final distance = request.distanceKm;

        return Padding(
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
