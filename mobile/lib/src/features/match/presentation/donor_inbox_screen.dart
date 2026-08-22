import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../donor/presentation/donor_setup_screen.dart';
import '../application/match_providers.dart';
import '../domain/match.dart';
import 'match_detail_screen.dart';

/// `GET /matches/me` — the donor's alert inbox.
///
/// The only 404 this endpoint produces is `DONOR_PROFILE_NOT_FOUND`
/// (`MatchService.requireProfile`) — a REQUESTER-only account has no donor
/// profile and therefore no matches, which is a normal state, not a fault. So any
/// [NotFoundFailure] here is read as "not a donor yet", not shown as an error.
class DonorInboxScreen extends ConsumerWidget {
    const DonorInboxScreen({super.key});

    static const String path = '/inbox';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final matches = ref.watch(myMatchesControllerProvider);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.inboxTitle)),
            body: SafeArea(
                child: RefreshIndicator(
                    onRefresh: () => ref.refresh(myMatchesControllerProvider.future),
                    child: switch (matches) {
                        AsyncValue(isLoading: true, hasValue: false) => const Center(
                            child: CircularProgressIndicator(key: Key('inbox-loading')),
                        ),
                        AsyncValue(hasError: true, error: NotFoundFailure()) =>
                            _becomeADonor(context, l10n),
                        AsyncValue(hasError: true) => Center(
                            child: Text(l10n.inboxFailed, key: const Key('inbox-failed')),
                        ),
                        AsyncValue(hasValue: true, value: final list) =>
                            _list(context, l10n, list ?? const []),
                        _ => const SizedBox.shrink(),
                    },
                ),
            ),
        );
    }

    Widget _becomeADonor(BuildContext context, AppLocalizations l10n) {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                            l10n.inboxNoDonorProfile,
                            key: const Key('inbox-no-donor-profile'),
                            textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: () => context.push(DonorSetupScreen.path),
                            child: Text(l10n.donorProfileCta),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _list(BuildContext context, AppLocalizations l10n, List<Match> list) {
        if (list.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        l10n.inboxEmpty,
                        key: const Key('inbox-empty'),
                        textAlign: TextAlign.center,
                    ),
                ),
            );
        }
        return ListView.builder(
            key: const Key('inbox-list'),
            itemCount: list.length,
            itemBuilder: (context, index) => _MatchTile(match: list[index]),
        );
    }
}

class _MatchTile extends StatelessWidget {
    const _MatchTile({required this.match});

    final Match match;

    @override
    Widget build(BuildContext context) {
        final request = match.request;
        final distance = request.distanceKm;
        return ListTile(
            key: Key('inbox-match-${match.matchId}'),
            title: Text('${request.patientBloodType.wireValue} · ${request.hospitalName}'),
            subtitle: Text(distance == null ? request.urgency.wireValue : '~$distance km'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(MatchDetailScreen.routeFor(match.matchId)),
        );
    }
}
