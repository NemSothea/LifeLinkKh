import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/error/result.dart';
import '../../../core/firebase/firestore_providers.dart';
import '../../request/application/request_providers.dart';
import '../data/firestore_match_repository.dart';
import '../data/match_sync_dao.dart';
import '../data/offline_first_match_repository.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';
import 'match_service.dart';
import 'match_sync_service.dart';

part 'match_providers.g.dart';

@Riverpod(keepAlive: true)
MatchSyncDao matchSyncDao(MatchSyncDaoRef ref) => MatchSyncDao(ref.watch(appDatabaseProvider));

/// The network half, on its own. The sync engine drains through this one: going
/// through [matchRepositoryProvider] would re-queue every write it just sent.
@Riverpod(keepAlive: true)
MatchRepository remoteMatchRepository(RemoteMatchRepositoryRef ref) => FirestoreMatchRepository(
    ref.watch(firestoreProvider),
    ref.watch(firestoreRequestRepositoryProvider),
    currentUid: ref.watch(currentUidProvider),
);

/// The swap. Everything above this line — service, notifier, every widget — was
/// written against [MatchRepository] and did not change when SQLite arrived.
@Riverpod(keepAlive: true)
MatchRepository matchRepository(MatchRepositoryRef ref) => OfflineFirstMatchRepository(
    ref.watch(remoteMatchRepositoryProvider),
    ref.watch(matchSyncDaoProvider),
);

@Riverpod(keepAlive: true)
MatchSyncService matchSyncService(MatchSyncServiceRef ref) {
    final service = MatchSyncService(
        ref.watch(remoteMatchRepositoryProvider),
        ref.watch(matchSyncDaoProvider),
    );
    service.syncOnReconnect(Connectivity().onConnectivityChanged);
    ref.onDispose(service.dispose);
    return service;
}

@Riverpod(keepAlive: true)
MatchService matchService(MatchServiceRef ref) => MatchService(ref.watch(matchRepositoryProvider));

/// The donor's inbox. `keepAlive` so it survives navigating into and back out of
/// a match's detail screen.
@Riverpod(keepAlive: true)
class MyMatchesController extends _$MyMatchesController {
    @override
    Future<List<Match>> build() async {
        final result = await ref.watch(matchServiceProvider).loadMine();
        return switch (result) {
            Success(value: final matches) => matches,
            Failed(failure: final failure) => throw failure,
        };
    }

    /// Accepts or declines, then folds the result into the cached list in place —
    /// a full reload would flash a spinner over an inbox the donor is mid-read on.
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) async {
        final result = await ref.read(matchServiceProvider).respond(matchId, response);
        if (result case Success(value: final respondResult)) {
            // A queued answer is worth one immediate drain attempt: the network may
            // have come back between the write and now, and the badge clearing on
            // its own is better than a badge that waits for a connectivity event.
            if (respondResult.isPending) {
                unawaited(ref.read(matchSyncServiceProvider).triggerSync());
            }
            final current = state.valueOrNull;
            if (current != null) {
                state = AsyncData([
                    for (final match in current)
                        if (match.matchId == matchId)
                            match.copyWith(
                                response: respondResult.response,
                                isPending: respondResult.isPending,
                                request: respondResult.requesterContact == null
                                    ? match.request
                                    : match.request.withRequesterContact(
                                        respondResult.requesterContact!,
                                    ),
                            )
                        else
                            match,
                ]);
            }
        }
        return result;
    }
}
