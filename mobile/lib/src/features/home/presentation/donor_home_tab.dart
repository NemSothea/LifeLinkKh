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
                                // No donor profile means no matches — already covered by the
                                // card above, so this is not a second error to show.
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
            return Text(l10n.inboxEmpty, key: const Key('donor-home-matches-empty'));
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
        final request = match.request;
        final distance = request.distanceKm;
        return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
                key: Key('donor-home-match-${match.matchId}'),
                title: Text('${request.patientBloodType.wireValue} · ${request.hospitalName}'),
                subtitle: Text(
                    distance == null ? request.urgency.wireValue : '~$distance km',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(MatchDetailScreen.routeFor(match.matchId)),
            ),
        );
    }
}
