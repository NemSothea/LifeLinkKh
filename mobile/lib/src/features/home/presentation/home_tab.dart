import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../../core/time/relative_time.dart';
import '../../../core/widgets/retryable_failure.dart';
import '../../donation/presentation/donation_guide_screen.dart';
import '../../donor/application/donor_providers.dart';
import '../../donor/domain/donor_profile.dart';
import '../../donor/presentation/donor_setup_screen.dart';
import '../../donor/presentation/eligibility_card.dart';
import '../../match/application/match_providers.dart';
import '../../match/domain/match.dart';
import '../../match/domain/match_response_type.dart';
import '../../match/presentation/match_detail_screen.dart';
import '../../request/application/request_providers.dart';
import '../../request/domain/blood_request.dart';
import '../../request/domain/urgency.dart';
import '../../request/presentation/request_detail_screen.dart';
import '../../request/presentation/request_form_screen.dart';
import '../../request/presentation/urgency_badge.dart';

/// The Home tab — `GLOBAL-home-dashboard` prototype: the eligibility card first (the one
/// thing a donor opens the app to check), then everything they might do or be waiting on.
/// Notifications get missed and swiped away; this is what someone sees when they open the
/// app unprompted instead.
///
/// One Home for everyone, deliberately. Until 2026-09-24 this was `DonorHomeTab` and a
/// separate `RequesterHomeTab` existed beside it, chosen by `users.role`. Nothing ever set
/// that role to `REQUESTER` — `AuthService.DEFAULT_ROLE` is `DONOR` and no endpoint or screen
/// changes it — so the requester screen was unreachable for every real account, and the list
/// of your own requests along with it. The split also contradicted the product: `prd.md` says
/// the app's expected requester IS a donor with a relative in trouble, and
/// `RequestController` lets any signed-in user post. Asking someone to be one or the other
/// was answering a question the product had already decided not to ask.
class HomeTab extends ConsumerWidget {
    const HomeTab({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final profile = ref.watch(donorProfileControllerProvider);
        final matches = ref.watch(myMatchesControllerProvider);
        final myRequests = ref.watch(myRequestsControllerProvider);
        // Nearby-requests needs a donor profile to mean anything (`GET /matches/me` 404s
        // without one) — gated on the profile actually loading in, not on the match
        // call's own error, so a donor with no profile never sees a heading with
        // nothing under it while the "become a donor" card above says the same thing.
        final hasDonorProfile = profile.valueOrNull != null;
        // Whether the board below has anything to show decides how loudly the empty inbox
        // says it is empty: a full-height reassurance card above a populated list is two
        // answers to a question nobody asked twice.
        final board = ref.watch(publicBoardControllerProvider);
        final boardHasRequests = (board.valueOrNull ?? const []).isNotEmpty;
        // One spinner for the whole tab, not one per section. Each section used to show its
        // own while its first answer was in flight, so opening the app put two or three
        // spinners on screen at once, stacked down the list. Until every section has an
        // answer, the tab shows one; after that, a pull-to-refresh keeps the old values up.
        bool firstLoad(AsyncValue<Object?> value) => value.isLoading && !value.hasValue;
        final loading = firstLoad(profile) ||
            (hasDonorProfile && firstLoad(matches)) ||
            firstLoad(myRequests) ||
            firstLoad(board);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
            body: SafeArea(
                child: RefreshIndicator(
                    onRefresh: () => Future.wait([
                        ref.refresh(donorProfileControllerProvider.future),
                        ref.refresh(myMatchesControllerProvider.future),
                        ref.refresh(myRequestsControllerProvider.future),
                        ref.refresh(publicBoardControllerProvider.future),
                    ]),
                    child: ListView(
                        key: const Key('home-list'),
                        // Without this the pull gesture is dead whenever the
                        // content is shorter than the viewport — which on this
                        // tab is the common case, not the edge case.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: loading
                            ? const [
                                SizedBox(height: 48),
                                Center(
                                    child: CircularProgressIndicator(key: Key('home-loading')),
                                ),
                            ]
                            : [
                            switch (profile) {
                                AsyncValue(hasValue: true, value: final DonorProfile loaded) =>
                                    EligibilityCard(eligibility: loaded.eligibility),
                                AsyncValue(hasValue: true) => _becomeADonor(context, l10n),
                                _ => const SizedBox.shrink(),
                            },
                            // Under the eligibility answer, for donor and not-yet-donor alike:
                            // "can I donate?" is followed by "what happens if I do?", and the
                            // person with no profile yet is the one who most needs the answer.
                            if (profile.hasValue)
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                        key: const Key('home-donation-guide'),
                                        icon: const Icon(Icons.info_outline),
                                        label: Text(l10n.donateGuideCta),
                                        onPressed: () => context.push(DonationGuideScreen.path),
                                    ),
                                ),
                            // Above the alerts, and shown to everyone. Posting a request is
                            // the one thing on this screen that cannot wait for the person to
                            // go looking for it, and the people most likely to need it are
                            // frightened rather than familiar with the app.
                            const SizedBox(height: 20),
                            _RequestBloodButton(
                                label: l10n.requestNewCta,
                                onPressed: () => context.push(RequestFormScreen.path),
                            ),
                            if (hasDonorProfile) ...[
                                const SizedBox(height: 24),
                                Text(
                                    l10n.homeNearbyRequestsHeading,
                                    style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                switch (matches) {
                                    // Covered by `hasDonorProfile` above — kept only as a
                                    // defensive fallback if the two calls ever disagree.
                                    AsyncValue(hasError: true, error: NotFoundFailure()) =>
                                        const SizedBox.shrink(),
                                    AsyncValue(hasError: true) => RetryableFailure(
                                        key: const Key('donor-home-matches-failed'),
                                        message: l10n.inboxFailed,
                                        onRetry: () =>
                                            ref.invalidate(myMatchesControllerProvider),
                                    ),
                                    AsyncValue(hasValue: true, value: final list) => _nearbyList(
                                        context,
                                        l10n,
                                        list ?? const [],
                                        boardHasRequests: boardHasRequests,
                                    ),
                                    _ => const SizedBox.shrink(),
                                },
                            ],
                            // Shown to every signed-in donor, profile or not. The match
                            // inbox above answers "what was I alerted about" and is empty
                            // most days by design; this answers "who needs blood right
                            // now", which is the question someone opening the app
                            // unprompted actually has. Before it existed, the common case
                            // for this screen was a status banner and blank space.
                            ..._myRequests(context, ref, l10n, myRequests),
                            const SizedBox(height: 24),
                            _BoardSection(alerted: matches.valueOrNull ?? const []),
                        ],
                    ),
                ),
            ),
        );
    }

    /// Your own requests, and only when you have some. An empty "your requests" card under
    /// the button that creates one is a label for a thing that is not there — the button
    /// above already says the feature exists. A failure still shows, because silence there
    /// would read as "you have none" on a screen where that is a very different sentence.
    List<Widget> _myRequests(
        BuildContext context,
        WidgetRef ref,
        AppLocalizations l10n,
        AsyncValue<List<BloodRequest>> requests,
    ) {
        final list = requests.valueOrNull ?? const <BloodRequest>[];
        if (requests.hasError) {
            return [
                const SizedBox(height: 24),
                RetryableFailure(
                    key: const Key('home-my-requests-failed'),
                    message: l10n.myRequestsFailed,
                    onRetry: () => ref.invalidate(myRequestsControllerProvider),
                ),
            ];
        }
        if (list.isEmpty) {
            return const [];
        }
        return [
            const SizedBox(height: 24),
            Text(l10n.myRequestsCta, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
                key: const Key('home-my-request-list'),
                children: [for (final request in list) _RequestTile(request: request)],
            ),
        ];
    }

    Widget _becomeADonor(BuildContext context, AppLocalizations l10n) {
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(l10n.donorProfileCta),
                        const SizedBox(height: 12),
                        FilledButton(
                            key: const Key('donor-home-start-setup'),
                            onPressed: () => context.push(DonorSetupScreen.path),
                            child: Text(l10n.donorSetupTitle),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _nearbyList(
        BuildContext context,
        AppLocalizations l10n,
        List<Match> matches, {
        required bool boardHasRequests,
    }) {
        if (matches.isEmpty) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            // With a populated board underneath, "you have no alerts" is a caption, not an
            // event: one muted line, and the ~200px the card used to take goes to the
            // requests that actually need reading.
            if (boardHasRequests) {
                return Padding(
                    key: const Key('donor-home-matches-empty'),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                        children: [
                            Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    l10n.inboxEmpty,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                    ),
                                ),
                            ),
                        ],
                    ),
                );
            }
            // Nothing below it either — then this card is the screen, and it should look
            // like something rather than a stray line.
            return Card(
                key: const Key('donor-home-matches-empty'),
                margin: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    child: Column(
                        children: [
                            Icon(Icons.check_circle_outline, size: 36, color: scheme.primary),
                            const SizedBox(height: 12),
                            Text(
                                l10n.inboxEmpty,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                    ),
                ),
            );
        }

        final unanswered = [for (final m in matches) if (m.response == null) m]..sort(_byTriage);
        final answered = [for (final m in matches) if (m.response != null) m]
            ..sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));

        return Column(
            key: const Key('donor-home-matches-list'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Only labelled when there is a second group to tell it apart from —
                // a lone heading over the only list on screen is noise.
                if (unanswered.isNotEmpty && answered.isNotEmpty)
                    _GroupLabel(text: l10n.matchNeedsAnswer),
                for (final match in unanswered) _NearbyRequestTile(match: match),
                if (answered.isNotEmpty) ...[
                    _GroupLabel(
                        text: l10n.matchAlreadyAnswered,
                        topPadding: unanswered.isEmpty ? 0 : 12,
                    ),
                    for (final match in answered) _NearbyRequestTile(match: match),
                ],
            ],
        );
    }
}

/// Triage order for requests this donor has not answered yet, most urgent first.
///
/// The server returns `GET /matches/me` newest-first, which is the wrong order for this
/// list: a CRITICAL request 1 km away posted an hour ago belongs above a ROUTINE one
/// posted five minutes ago, and before this sort it did not get there. The portal's own
/// `sortByUrgency` makes the same argument for hospital staff — this is the donor half
/// of it, with distance as the tie-break because two equally urgent requests are
/// separated by which one this donor can actually reach.
int _byTriage(Match a, Match b) {
    final urgency = _urgencyRank(a.request.urgency).compareTo(_urgencyRank(b.request.urgency));
    if (urgency != 0) return urgency;

    final distanceA = a.request.distanceKm;
    final distanceB = b.request.distanceKm;
    // A donor with no coordinates has a null distance on every row (ADR 0003) — that is
    // a whole-list property, not a per-row one, so nulls sort last and the comparison
    // falls through to recency for everyone.
    if (distanceA != null && distanceB != null && distanceA != distanceB) {
        return distanceA.compareTo(distanceB);
    }
    if (distanceA == null && distanceB != null) return 1;
    if (distanceA != null && distanceB == null) return -1;

    return b.request.createdAt.compareTo(a.request.createdAt);
}

int _urgencyRank(Urgency urgency) => switch (urgency) {
    Urgency.critical => 0,
    Urgency.urgent => 1,
    Urgency.routine => 2,
};

class _GroupLabel extends StatelessWidget {
    const _GroupLabel({required this.text, this.topPadding = 0});

    final String text;
    final double topPadding;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return Padding(
            padding: EdgeInsets.only(top: topPadding, bottom: 8),
            child: Text(
                text.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                ),
            ),
        );
    }
}

class _NearbyRequestTile extends StatelessWidget {
    const _NearbyRequestTile({required this.match});

    final Match match;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final request = match.request;
        final distance = request.distanceKm;
        final answered = match.response != null;
        final isCritical = request.urgency == Urgency.critical && !answered;

        return Card(
            margin: const EdgeInsets.only(bottom: 10),
            // A CRITICAL request this donor has not answered gets a red spine, the same
            // device the portal uses on its own critical rows. Answered rows lose it —
            // once you have replied, the row is a receipt, not a call to action.
            shape: isCritical
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: scheme.primary, width: 1.5),
                )
                : null,
            child: Opacity(
                opacity: answered ? 0.62 : 1,
                child: ListTile(
                    key: Key('donor-home-match-${match.matchId}'),
                    leading: CircleAvatar(
                        backgroundColor: answered ? scheme.surfaceContainerHighest : scheme.primary,
                        foregroundColor: answered ? scheme.onSurfaceVariant : scheme.onPrimary,
                        child: Text(
                            request.patientBloodType.wireValue,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                    ),
                    title: Text(request.hospitalName, overflow: TextOverflow.ellipsis),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        // Wrap, not Row: a long badge label plus the distance must not overflow
                        // the tile's fixed subtitle width — it drops to a second line instead.
                        child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                                if (answered)
                                    _AnsweredChip(response: match.response!)
                                else
                                    UrgencyBadge(urgency: request.urgency),
                                if (distance != null)
                                    Text('~$distance km', style: theme.textTheme.bodySmall),
                                // The age sits next to the distance on purpose: together
                                // they are the whole "can I get there in time" question.
                                Text(
                                    formatRelativeTime(context, request.createdAt),
                                    key: Key('donor-home-match-${match.matchId}-age'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                    ),
                                ),
                            ],
                        ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(MatchDetailScreen.routeFor(match.matchId)),
                ),
            ),
        );
    }
}

class _AnsweredChip extends StatelessWidget {
    const _AnsweredChip({required this.response});

    final MatchResponseType response;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final accepted = response == MatchResponseType.accepted;

        return DecoratedBox(
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(
                            accepted ? Icons.check : Icons.close,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                            accepted ? l10n.matchStateAccepted : l10n.matchStateDeclined,
                            style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// "Who needs blood right now", for a donor whose own alert inbox is empty.
///
/// Reads the same public board the web portal serves (DEC-009), minus the requests this
/// donor was already alerted to — those are shown above with accept and decline on them,
/// and repeating them here would make one request look like two.
class _BoardSection extends ConsumerWidget {
    const _BoardSection({required this.alerted});

    /// The donor's own matches, used only to subtract them from the board.
    final List<Match> alerted;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final board = ref.watch(publicBoardControllerProvider);
        final alertedIds = {for (final match in alerted) match.request.id};

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(l10n.homeBoardHeading, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                    l10n.homeBoardSubheading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ),
                const SizedBox(height: 8),
                switch (board) {
                    AsyncValue(hasError: true) => RetryableFailure(
                        key: const Key('donor-home-board-failed'),
                        message: l10n.homeBoardFailed,
                        onRetry: () => ref.invalidate(publicBoardControllerProvider),
                    ),
                    AsyncValue(hasValue: true, value: final list) => _boardList(
                        context,
                        l10n,
                        [for (final r in list ?? const <BloodRequest>[]) if (!alertedIds.contains(r.id)) r],
                    ),
                    _ => const SizedBox.shrink(),
                },
            ],
        );
    }

    Widget _boardList(BuildContext context, AppLocalizations l10n, List<BloodRequest> requests) {
        if (requests.isEmpty) {
            return Padding(
                key: const Key('donor-home-board-empty'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                    l10n.homeBoardEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ),
            );
        }
        // Most urgent first, then newest. The server returns newest-first, which buries a
        // CRITICAL request under routine ones posted minutes later.
        final sorted = [...requests]..sort((a, b) {
            final byUrgency = a.urgency.index.compareTo(b.urgency.index);
            return byUrgency != 0 ? byUrgency : b.createdAt.compareTo(a.createdAt);
        });
        return Column(
            key: const Key('donor-home-board-list'),
            children: [for (final request in sorted) _BoardRequestTile(request: request)],
        );
    }
}

/// One row of the public board. Deliberately not tappable: this donor was not alerted to
/// this request, so there is no match to open and nothing to accept. It is information —
/// where blood is needed and how badly — not a call to action aimed at them.
class _BoardRequestTile extends StatelessWidget {
    const _BoardRequestTile({required this.request});

    final BloodRequest request;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final district = request.hospitalDistrictLabel(
            Localizations.localeOf(context).languageCode,
        );

        return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
                key: Key('donor-home-board-${request.id}'),
                leading: CircleAvatar(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurfaceVariant,
                    child: Text(
                        request.patientBloodType.wireValue,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                ),
                title: Text(request.hospitalName, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                            UrgencyBadge(urgency: request.urgency),
                            if (district != null)
                                Text(district, style: theme.textTheme.bodySmall),
                            Text(
                                formatRelativeTime(context, request.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                ),
                            ),
                        ],
                    ),
                ),
            ),
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
                key: const Key('home-request-new'),
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
                key: Key('home-request-${request.id}'),
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
                                key: Key('home-request-${request.id}-age'),
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
