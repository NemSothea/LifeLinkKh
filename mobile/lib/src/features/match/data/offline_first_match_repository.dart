import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';
import 'match_sync_dao.dart';

/// Writes the donor's answer to SQLite first, then tries the network.
///
/// Swapping this in front of [MatchRepository] changed one line in
/// `match_providers.dart` and nothing above it: the service, the notifier and
/// every widget are untouched. That is rule S4 — depend on abstractions — paying
/// for itself.
///
/// The rule it implements is in `docs/mobile/local-db-and-sync.md`: the local
/// write always succeeds, the server always decides. A refusal is recorded, not
/// swallowed.
final class OfflineFirstMatchRepository implements MatchRepository {
    const OfflineFirstMatchRepository(this._remote, this._dao);

    final MatchRepository _remote;
    final MatchSyncDao _dao;

    /// The inbox still comes from the server — this slice caches decisions, not
    /// requests. What it adds is the overlay: a match the donor answered while
    /// offline comes back from `GET /matches/me` with `response: null`, because
    /// the server has not heard about it. Without the overlay the app would show
    /// the donor an unanswered request they already accepted.
    @override
    Future<Result<List<Match>>> fetchMine() async {
        final result = await _remote.fetchMine();
        if (result case Success(value: final matches)) {
            final local = {for (final row in await _dao.pendingRows()) row.id: row};
            if (local.isEmpty) return result;
            return Success([
                for (final match in matches)
                    if (local[match.matchId] case final row?)
                        match.copyWith(
                            response: MatchResponseType.fromWire(row.response),
                            isPending: true,
                        )
                    else
                        match,
            ]);
        }
        return result;
    }

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) async {
        final respondedAt = DateTime.now();
        final key = await _dao.saveLocalResponse(
            matchId: matchId,
            // The request id is not needed to send the answer — the match id
            // addresses the endpoint — but the row keeps it so the table means
            // something on its own when the request cache lands.
            bloodRequestId: matchId,
            response: response.wireValue,
            respondedAt: respondedAt,
        );

        final sent = await _remote.respond(matchId, response, idempotencyKey: key);
        switch (sent) {
            case Success(value: final result):
                await _dao.markSynced(matchId);
                return Success(result);

            // Unreachable, not refused. The answer stays queued and the donor sees
            // it as pending — this is the whole point of the feature.
            case Failed(failure: NetworkFailure()) || Failed(failure: ServerFailure()):
                return Success(
                    RespondResult(
                        matchId: matchId,
                        response: response,
                        respondedAt: respondedAt,
                        isPending: true,
                    ),
                );

            // The server answered and said no — the request closed, or this donor
            // already responded. Server-wins: the local answer is rolled back and
            // the failure goes up to the screen unchanged.
            case Failed(failure: final failure):
                await _dao.markRejected(matchId, failure.message);
                return Failed(failure);
        }
    }
}
