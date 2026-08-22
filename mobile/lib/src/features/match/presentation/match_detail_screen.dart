import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../../request/domain/blood_request.dart';
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
                    Text(
                        request.urgency.wireValue,
                        key: const Key('match-urgency'),
                        style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        request.patientBloodType.wireValue,
                        style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text('${l10n.requestUnitsLabel}: ${request.unitsNeeded}'),
                    const Divider(height: 32),
                    Text(request.hospitalName, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                        switch ((request.hospitalDistrictLabel(languageCode), request.distanceKm)) {
                            (final String district, final double km) => '$district · ~$km km',
                            (final String district, null) => district,
                            (null, final double km) => '~$km km',
                            (null, null) => '',
                        },
                    ),
                    const SizedBox(height: 8),
                    Text(
                        DateFormat.yMMMd(languageCode).add_jm().format(request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 32),
                    Text(
                        l10n.inboxYourBloodTypeCompatible(match.myBloodType.wireValue),
                        key: const Key('match-compatible'),
                    ),
                    const SizedBox(height: 32),
                    if (match.response == null) ..._respondActions(l10n),
                    if (match.response == MatchResponseType.accepted)
                        _acceptedResult(context, l10n, request),
                    if (match.response == MatchResponseType.declined)
                        Text(l10n.matchDeclinedTitle, key: const Key('match-declined')),
                ],
            ),
        );
    }

    List<Widget> _respondActions(AppLocalizations l10n) => [
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
                            : () => _respond(MatchResponseType.declined),
                        child: Text(l10n.matchDeclineCta),
                    ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    flex: 2,
                    child: FilledButton(
                        key: const Key('match-accept'),
                        onPressed: _isResponding
                            ? null
                            : () => _respond(MatchResponseType.accepted),
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
