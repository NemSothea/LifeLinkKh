import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/database/app_database.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/application/match_sync_service.dart';
import 'package:lifelink_kh/src/features/match/data/match_sync_dao.dart';
import 'package:lifelink_kh/src/features/match/data/offline_first_match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

/// A network that can be switched off, and that remembers what it was asked.
final class _StubRemote implements MatchRepository {
    _StubRemote({this.failure});

    Failure? failure;
    List<Match> matches = const [];

    final List<String?> seenIdempotencyKeys = [];
    int respondCalls = 0;

    @override
    Future<Result<List<Match>>> fetchMine() async =>
        failure == null ? Success(matches) : Failed(failure!);

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) async {
        respondCalls++;
        seenIdempotencyKeys.add(idempotencyKey);
        if (failure != null) return Failed(failure!);
        return Success(
            RespondResult(
                matchId: matchId,
                response: response,
                respondedAt: DateTime.utc(2026, 9, 21, 10),
            ),
        );
    }
}

Match _match(String id, {MatchResponseType? response}) => Match(
    matchId: id,
    request: BloodRequest(
        id: 'request-$id',
        patientBloodType: BloodType.oNegative,
        unitsNeeded: 2,
        urgency: Urgency.urgent,
        status: RequestStatus.open,
        hospitalName: 'National Blood Transfusion Center',
        createdAt: DateTime.utc(2026, 9, 21, 9),
        alertedCount: 3,
        acceptedCount: 0,
    ),
    myBloodType: BloodType.oNegative,
    notifiedAt: DateTime.utc(2026, 9, 21, 9, 5),
    response: response,
);

void main() {
    late AppDatabase database;
    late MatchSyncDao dao;

    setUp(() {
        database = AppDatabase.memory();
        dao = MatchSyncDao(database);
    });

    tearDown(() => database.close());

    group('the local write', () {
        test('an answer and its queue row are written together, or not at all', () async {
            await dao.saveLocalResponse(
                matchId: 'match-1',
                bloodRequestId: 'request-1',
                response: 'ACCEPTED',
                respondedAt: DateTime.utc(2026, 9, 21, 10),
            );

            final row = await dao.rowFor('match-1');
            expect(row?.response, 'ACCEPTED');
            expect(row?.isPending, isTrue);
            expect(await dao.pendingQueue(), hasLength(1));
        });

        test('the same idempotency key is kept for the life of the queued row', () async {
            final key = await dao.saveLocalResponse(
                matchId: 'match-1',
                bloodRequestId: 'request-1',
                response: 'ACCEPTED',
                respondedAt: DateTime.utc(2026, 9, 21, 10),
            );

            final queued = await dao.pendingQueue();
            expect(queued.single.idempotencyKey, key);

            await dao.recordAttempt(queued.single.id, DateTime.utc(2026, 9, 21, 10, 1));
            final afterRetry = await dao.pendingQueue();
            expect(afterRetry.single.idempotencyKey, key, reason: 'a retry must replay the key');
            expect(afterRetry.single.retryCount, 1);
        });
    });

    group('answering with no network', () {
        test('the answer succeeds, is marked pending, and reveals no contact', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);

            final result = await repository.respond('match-1', MatchResponseType.accepted);

            expect(result, isA<Success<RespondResult>>());
            final value = (result as Success<RespondResult>).value;
            expect(value.isPending, isTrue);
            expect(
                value.requesterContact,
                isNull,
                reason: 'the contact is the server\'s to reveal; offline there is no server',
            );
            expect(await dao.pendingQueue(), hasLength(1));
        });

        test('the inbox shows the queued answer, not the server\'s stale null', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);

            remote.failure = null;
            remote.matches = [_match('match-1'), _match('match-2')];

            final result = await repository.fetchMine();
            final matches = (result as Success<List<Match>>).value;

            expect(matches.first.response, MatchResponseType.accepted);
            expect(matches.first.isPending, isTrue);
            expect(matches.last.response, isNull);
            expect(matches.last.isPending, isFalse);
        });
    });

    group('answering with a network', () {
        test('the answer is sent, and nothing is left in the queue', () async {
            final remote = _StubRemote();
            final repository = OfflineFirstMatchRepository(remote, dao);

            final result = await repository.respond('match-1', MatchResponseType.accepted);

            expect((result as Success<RespondResult>).value.isPending, isFalse);
            expect(await dao.pendingQueue(), isEmpty);
            expect((await dao.rowFor('match-1'))?.isPending, isFalse);
        });

        test('a refusal rolls the local answer back and keeps the reason', () async {
            final remote = _StubRemote(
                failure: const ConflictFailure(code: 'ALREADY_FULFILLED', message: 'already fulfilled'),
            );
            final repository = OfflineFirstMatchRepository(remote, dao);

            final result = await repository.respond('match-1', MatchResponseType.accepted);

            expect(result, isA<Failed<RespondResult>>());
            final row = await dao.rowFor('match-1');
            expect(row?.response, isNull, reason: 'server wins — the local answer loses');
            expect(row?.rejectedReason, 'already fulfilled');
            expect(await dao.pendingQueue(), isEmpty);
        });
    });

    group('the sync engine', () {
        test('drains the queue when the network returns', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);
            await repository.respond('match-2', MatchResponseType.declined);
            expect(await dao.pendingQueue(), hasLength(2));

            remote.failure = null;
            await MatchSyncService(remote, dao).triggerSync();

            expect(await dao.pendingQueue(), isEmpty);
            expect((await dao.rowFor('match-1'))?.isPending, isFalse);
            expect((await dao.rowFor('match-2'))?.isPending, isFalse);
        });

        test('replays the key the write was queued with', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);
            final queuedKey = (await dao.pendingQueue()).single.idempotencyKey;

            remote.failure = null;
            await MatchSyncService(remote, dao).triggerSync();

            expect(remote.seenIdempotencyKeys.last, queuedKey);
        });

        test('a concurrent drain is a no-op, not a second send', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);

            remote.failure = null;
            final callsBefore = remote.respondCalls;
            final service = MatchSyncService(remote, dao);
            await Future.wait([service.triggerSync(), service.triggerSync()]);

            expect(
                remote.respondCalls - callsBefore,
                1,
                reason: 'the guard exists so one acceptance is never sent twice',
            );
        });

        test('backoff grows 1, 2, 4, 8 and stops at 8', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);

            final service = MatchSyncService(remote, dao);
            expect(service.backoff, const Duration(seconds: 1));
            for (final expected in [2, 4, 8, 8]) {
                await service.triggerSync();
                expect(service.backoff, Duration(seconds: expected));
            }
        });

        test('backoff resets once a write gets through', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);

            final service = MatchSyncService(remote, dao);
            await service.triggerSync();
            expect(service.backoff, const Duration(seconds: 2));

            remote.failure = null;
            await service.triggerSync();
            expect(service.backoff, const Duration(seconds: 1));
        });

        test('a refusal on arrival drops the write and moves on', () async {
            final remote = _StubRemote(failure: const NetworkFailure());
            final repository = OfflineFirstMatchRepository(remote, dao);
            await repository.respond('match-1', MatchResponseType.accepted);

            remote.failure = const ConflictFailure(
                code: 'ALREADY_FULFILLED',
                message: 'already fulfilled',
            );
            await MatchSyncService(remote, dao).triggerSync();

            expect(await dao.pendingQueue(), isEmpty);
            expect((await dao.rowFor('match-1'))?.rejectedReason, 'already fulfilled');
        });
    });
}
