import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/database/app_database.dart';
import 'package:lifelink_kh/src/features/auth/application/local_data_eraser.dart';
import 'package:lifelink_kh/src/features/match/data/match_sync_dao.dart';

import 'support/auth_fakes.dart';

/// What sign-out and account deletion leave on a shared phone (SEC-REVIEW-003 F-07, F-20):
/// nothing of the last user — no cached answer, no queued write, no FCM token.
void main() {
    late AppDatabase database;
    late FakePushTokenSource pushTokens;
    late int firestoreClears;

    setUp(() async {
        database = AppDatabase.memory();
        pushTokens = FakePushTokenSource();
        firestoreClears = 0;
        // An answer given offline: one row in each table, the state F-07 describes.
        await MatchSyncDao(database).saveLocalResponse(
            matchId: 'match-1',
            bloodRequestId: 'request-1',
            response: 'ACCEPTED',
            respondedAt: DateTime.utc(2026, 9, 29),
        );
    });

    tearDown(() async {
        await pushTokens.refreshes.close();
        await database.close();
    });

    LocalDataEraser eraserUnder({Future<void> Function()? clearFirestoreCache}) =>
        LocalDataEraser(
            database: database,
            pushTokens: pushTokens,
            clearFirestoreCache: clearFirestoreCache ?? () async => firestoreClears++,
        );

    Future<int> rowsIn(TableInfo<Table, Object?> table) async =>
        (await database.select(table).get()).length;

    test('empties every Drift table, clears the Firestore cache and deletes the FCM token',
        () async {
        expect(await rowsIn(database.requestMatchRows), 1);
        expect(await rowsIn(database.pendingSync), 1);

        await eraserUnder().erase();

        for (final table in database.allTables) {
            expect(await rowsIn(table), 0, reason: table.actualTableName);
        }
        expect(firestoreClears, 1);
        expect(pushTokens.deleteCount, 1);
    });

    test('a Firestore cache that cannot be cleared still leaves the tables empty', () async {
        await eraserUnder(clearFirestoreCache: () async => throw Exception('still running'))
            .erase();

        expect(await rowsIn(database.requestMatchRows), 0);
        expect(await rowsIn(database.pendingSync), 0);
        expect(pushTokens.deleteCount, 1);
    });

    test('a database that cannot be opened does not stop the rest, and nothing throws',
        () async {
        await database.close();
        database = AppDatabase.memory();
        await database.close();

        await eraserUnder().erase();

        expect(firestoreClears, 1);
        expect(pushTokens.deleteCount, 1);
    });
}
