import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../donor/application/donor_providers.dart';
import '../../donor/domain/donor_profile.dart';
import '../../donor/presentation/donor_setup_screen.dart';
import '../../donor/presentation/eligibility_card.dart';
import '../../match/application/match_providers.dart';
import '../../match/domain/match.dart';
import '../../match/presentation/match_detail_screen.dart';
import '../../request/presentation/urgency_badge.dart';

/// Donor shell's Home tab — `GLOBAL-home-dashboard` prototype: the eligibility card
/// first (the one thing a donor opens the app to check), a recovery list of nearby
/// requests underneath it. Notifications get missed and swiped away; this is what a
/// donor sees when they open the app unprompted instead.
class DonorHomeTab extends ConsumerWidget {
    const DonorHomeTab({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final profile = ref.watch(donorProfileControllerProvider);
        final matches = ref.watch(myMatchesControllerProvider);
        // Nearby-requests needs a donor profile to mean anything (`GET /matches/me` 404s
        // without one) — gated on the profile actually loading in, not on the match
        // call's own error, so a donor with no profile never sees a heading with
        // nothing under it while the "become a donor" card above says the same thing.
        final hasDonorProfile = profile.valueOrNull != null;

        return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
            body: SafeArea(
                child: RefreshIndicator(
                    onRefresh: () => Future.wait([
                        ref.refresh(donorProfileControllerProvider.future),
                        ref.refresh(myMatchesControllerProvider.future),
                    ]),
                    child: ListView(
                        key: const Key('donor-home-list'),
                        padding: const EdgeInsets.all(16),
                        children: [
                            switch (profile) {
                                AsyncValue(hasValue: true, value: final DonorProfile loaded) =>
                                    EligibilityCard(eligibility: loaded.eligibility),
                                AsyncValue(hasValue: true) => _becomeADonor(context, l10n),
                                AsyncError() => const SizedBox.shrink(),
                                _ => const Center(
                                    child: CircularProgressIndicator(
                                        key: Key('donor-home-profile-loading'),
                                    ),
                                ),
                            },
                            if (hasDonorProfile) ...[
                                const SizedBox(height: 24),
                                Text(
                                    l10n.homeNearbyRequestsHeading,
                                    style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                switch (matches) {
                                    AsyncValue(isLoading: true, hasValue: false) => const Center(
                                        child: CircularProgressIndicator(
                                            key: Key('donor-home-matches-loading'),
                                        ),
                                    ),
                                    // Covered by `hasDonorProfile` above — kept only as a
                                    // defensive fallback if the two calls ever disagree.
                                    AsyncValue(hasError: true, error: NotFoundFailure()) =>
                                        const SizedBox.shrink(),
                                    AsyncValue(hasError: true) => Text(
                                        l10n.inboxFailed,
                                        key: const Key('donor-home-matches-failed'),
                                    ),
                                    AsyncValue(hasValue: true, value: final list) => _nearbyList(
                                        context,
                                        l10n,
                                        list ?? const [],
                                    ),
                                    _ => const SizedBox.shrink(),
                                },
                            ],
                        ],
                    ),
                ),
            ),
        );
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

    Widget _nearbyList(BuildContext context, AppLocalizations l10n, List<Match> matches) {
        if (matches.isEmpty) {
            final scheme = Theme.of(context).colorScheme;
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
        return Column(
            key: const Key('donor-home-matches-list'),
            children: [
                for (final match in matches) _NearbyRequestTile(match: match),
            ],
        );
    }
}

class _NearbyRequestTile extends StatelessWidget {
    const _NearbyRequestTile({required this.match});

    final Match match;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        final request = match.request;
        final distance = request.distanceKm;
        return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
                key: Key('donor-home-match-${match.matchId}'),
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
                    // Wrap, not Row: a long badge label plus the distance must not overflow
                    // the tile's fixed subtitle width — it drops to a second line instead.
                    child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                            UrgencyBadge(urgency: request.urgency),
                            if (distance != null)
                                Text('~$distance km', style: Theme.of(context).textTheme.bodySmall),
                        ],
                    ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(MatchDetailScreen.routeFor(match.matchId)),
            ),
        );
    }
}
