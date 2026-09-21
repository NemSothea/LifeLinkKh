import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

part 'match_sync_dao.g.dart';

/// The SQL layer for the donor's offline answers.
///
/// The chain is Widget → Notifier → Service → Repository → **DAO** → SQLite: the
/// same dependency inversion the rest of the app already follows, with SQL as the
/// fifth link. Nothing above the repository knows Drift exists.
@DriftAccessor(tables: [RequestMatchRows, PendingSync])
class MatchSyncDao extends DatabaseAccessor<AppDatabase> with _$MatchSyncDaoMixin {
    MatchSyncDao(super.db);

    /// The entity name this DAO queues under. The queue is shared; the filter is not.
    static const String entity = 'request_match';

    /// Writes the donor's answer and its queue row in one transaction.
    ///
    /// Both rows or neither. A local answer the queue does not know about would
    /// be a decision the app shows as made and never sends — the exact failure
    /// offline-first exists to prevent.
    Future<String> saveLocalResponse({
        required String matchId,
        required String bloodRequestId,
        required String response,
        required DateTime respondedAt,
    }) async {
        final idempotencyKey = _newIdempotencyKey();
        await transaction(() async {
            await into(requestMatchRows).insertOnConflictUpdate(
                RequestMatchRowsCompanion.insert(
                    id: matchId,
                    bloodRequestId: bloodRequestId,
                    response: Value(response),
                    respondedAt: Value(respondedAt),
                    isPending: const Value(true),
                    rejectedReason: const Value(null),
                ),
            );
            await into(pendingSync).insert(
                PendingSyncCompanion.insert(
                    entity: entity,
                    entityId: matchId,
                    operation: 'update',
                    idempotencyKey: idempotencyKey,
                    queuedAt: respondedAt,
                ),
            );
        });
        return idempotencyKey;
    }

    /// Every queued answer, oldest first — the order the donor made them in.
    Future<List<PendingSyncData>> pendingQueue() =>
        (select(pendingSync)
              ..where((row) => row.entity.equals(entity))
              ..orderBy([(row) => OrderingTerm.asc(row.queuedAt)]))
            .get();

    /// Which matches still carry a badge. Watched, so a drain in the background
    /// clears the badge with no refresh call from the UI.
    Stream<List<RequestMatchRow>> watchPending() =>
        (select(requestMatchRows)..where((row) => row.isPending.equals(true))).watch();

    Future<List<RequestMatchRow>> pendingRows() =>
        (select(requestMatchRows)..where((row) => row.isPending.equals(true))).get();

    Future<RequestMatchRow?> rowFor(String matchId) =>
        (select(requestMatchRows)..where((row) => row.id.equals(matchId))).getSingleOrNull();

    /// The server confirmed it. Badge off, queue row gone.
    Future<void> markSynced(String matchId) async {
        await transaction(() async {
            await (update(requestMatchRows)..where((row) => row.id.equals(matchId))).write(
                const RequestMatchRowsCompanion(isPending: Value(false)),
            );
            await (delete(pendingSync)
                  ..where((row) => row.entity.equals(entity) & row.entityId.equals(matchId)))
                .go();
        });
    }

    /// The server refused it — the request closed while the donor was offline.
    ///
    /// Server-wins (`docs/mobile/local-db-and-sync.md`): the local answer loses,
    /// but it is not silently deleted. `rejectedReason` is what the screen turns
    /// into an explanation.
    Future<void> markRejected(String matchId, String reason) async {
        await transaction(() async {
            await (update(requestMatchRows)..where((row) => row.id.equals(matchId))).write(
                RequestMatchRowsCompanion(
                    isPending: const Value(false),
                    response: const Value(null),
                    respondedAt: const Value(null),
                    rejectedReason: Value(reason),
                ),
            );
            await (delete(pendingSync)
                  ..where((row) => row.entity.equals(entity) & row.entityId.equals(matchId)))
                .go();
        });
    }

    /// A retryable failure: the row stays queued and its attempt count grows.
    Future<void> recordAttempt(int queueId, DateTime at) async {
        final attempts = await _retryCountOf(queueId);
        await (update(pendingSync)..where((row) => row.id.equals(queueId))).write(
            PendingSyncCompanion(
                retryCount: Value(attempts + 1),
                lastAttemptAt: Value(at),
            ),
        );
    }

    Future<int> _retryCountOf(int queueId) async {
        final row = await (select(pendingSync)..where((r) => r.id.equals(queueId)))
            .getSingleOrNull();
        return row?.retryCount ?? 0;
    }

    /// Hex, not a UUID package. The key only has to be unique across this device's
    /// own queue, and adding a dependency to produce 16 random bytes is not a
    /// trade worth making.
    static String _newIdempotencyKey() {
        final random = Random.secure();
        final bytes = List<int>.generate(16, (_) => random.nextInt(256));
        return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    }
}
