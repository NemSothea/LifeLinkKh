import 'dart:async';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/match_sync_dao.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';

/// Drains the queue of answers the donor gave while offline.
///
/// **The S2 exception.** Rule S2 says services are stateless. This one is not: it
/// holds [_isDraining] as an idempotency guard, the current backoff, and a
/// subscription to connectivity changes. The exception is deliberate and it is
/// documented here rather than discovered later — a drain that can run twice at
/// once sends the same acceptance twice, and a service that cannot remember its
/// backoff hammers a server that is already struggling. S1, S3, S4, S5 and S6
/// still hold: it depends on the abstract [MatchRepository], it has no Flutter
/// import, and it returns nothing the UI has to interpret.
final class MatchSyncService {
    MatchSyncService(this._remote, this._dao);

    /// The raw network repository, never the offline-first decorator — draining
    /// through the decorator would re-queue every write it just dequeued.
    final MatchRepository _remote;
    final MatchSyncDao _dao;

    static const Duration firstBackoff = Duration(seconds: 1);
    static const Duration maxBackoff = Duration(seconds: 8);

    bool _isDraining = false;
    Duration _backoff = firstBackoff;
    StreamSubscription<Object?>? _connectivity;

    /// Current retry delay — 1s, 2s, 4s, 8s, then 8s forever. Exponential so that
    /// a thousand phones reconnecting to the same tower do not arrive together.
    Duration get backoff => _backoff;

    bool get isDraining => _isDraining;

    /// Drains until the queue is empty or something retryable stops it.
    ///
    /// Safe to call concurrently: the second call returns immediately rather than
    /// starting a second drain over the same rows.
    Future<void> triggerSync() async {
        if (_isDraining) return;
        _isDraining = true;
        try {
            for (final queued in await _dao.pendingQueue()) {
                final row = await _dao.rowFor(queued.entityId);
                final response = MatchResponseType.fromWire(row?.response);
                if (row == null || response == null) {
                    // The row went away underneath the queue — nothing to send.
                    await _dao.markSynced(queued.entityId);
                    continue;
                }

                final sent = await _remote.respond(
                    queued.entityId,
                    response,
                    idempotencyKey: queued.idempotencyKey,
                );

                switch (sent) {
                    case Success():
                        await _dao.markSynced(queued.entityId);
                        _backoff = firstBackoff;

                    // Retryable. Stop the drain here rather than marching through
                    // the rest of the queue into the same dead network.
                    case Failed(failure: NetworkFailure()) ||
                        Failed(failure: ServerFailure()) ||
                        Failed(failure: RateLimitedFailure()):
                        await _dao.recordAttempt(queued.id, DateTime.now());
                        _growBackoff();
                        return;

                    // Refused on arrival. Server-wins: the answer is dropped, the
                    // reason is kept, and the queue moves on to the next row.
                    case Failed(failure: final failure):
                        await _dao.markRejected(queued.entityId, failure.message);
                        _backoff = firstBackoff;
                }
            }
        } finally {
            _isDraining = false;
        }
    }

    /// Drains whenever the device gets a connection back.
    ///
    /// The stream's event type is deliberately loose: this class must not import
    /// `connectivity_plus`, or the service layer would depend on a plugin. The
    /// provider passes the plugin's stream in.
    void syncOnReconnect(Stream<Object?> connectivityChanges) {
        _connectivity?.cancel();
        _connectivity = connectivityChanges.listen((_) => triggerSync());
    }

    void dispose() {
        _connectivity?.cancel();
        _connectivity = null;
    }

    void _growBackoff() {
        final doubled = _backoff * 2;
        _backoff = doubled > maxBackoff ? maxBackoff : doubled;
    }
}
