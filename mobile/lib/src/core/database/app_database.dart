import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// A donor's own answer to one alert, held on the device.
///
/// Only the donor's own rows ever land here. The donor registry, other donors'
/// coordinates and the 27 `blood_compatibility` rows stay on the server —
/// see `docs/mobile/local-db-and-sync.md` for what is deliberately not cached.
///
/// `bloodRequestId` carries no foreign key: the request itself is not cached in
/// this slice, so a reference would point at a table that does not exist yet.
class RequestMatchRows extends Table {
    TextColumn get id => text()();
    TextColumn get bloodRequestId => text()();
    TextColumn get response => text().nullable()();
    DateTimeColumn get respondedAt => dateTime().nullable()();

    /// True between the local write and the server's confirmation. What the
    /// PENDING badge reads.
    BoolColumn get isPending => boolean().withDefault(const Constant(false))();

    /// Set when the server refused the queued write — the request closed while
    /// the donor was offline. Server-wins, and the donor is told why.
    TextColumn get rejectedReason => text().nullable()();

    @override
    Set<Column> get primaryKey => {id};
}

/// The write queue. One row per write that has not reached the server yet.
///
/// Generic in shape (`entity`/`entityId`/`operation`) because the next entity to
/// go offline-first is `donor_profile`, and a queue that only understands matches
/// would have to be rewritten rather than extended.
class PendingSync extends Table {
    IntColumn get id => integer().autoIncrement()();
    TextColumn get entity => text()();
    TextColumn get entityId => text()();
    TextColumn get operation => text()();

    /// Generated once, replayed unchanged on every retry. Without it, a retry
    /// after a response that was sent but never received records the donor's
    /// acceptance twice.
    TextColumn get idempotencyKey => text()();
    IntColumn get retryCount => integer().withDefault(const Constant(0))();
    DateTimeColumn get lastAttemptAt => dateTime().nullable()();
    DateTimeColumn get queuedAt => dateTime()();
}

@DriftDatabase(tables: [RequestMatchRows, PendingSync])
class AppDatabase extends _$AppDatabase {
    AppDatabase() : super(_openConnection());

    /// For tests and for the DAO's own unit tests — no phone, no file.
    AppDatabase.memory() : super(NativeDatabase.memory());

    @override
    int get schemaVersion => 1;

    @override
    MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async => m.createAll(),
        // Empty on purpose. There is no v0 in the wild, so there is nothing to
        // upgrade yet — but the hook exists now because the classic failure is
        // changing a table without bumping the version, which crashes every
        // installed app on launch. The v2 plan is in
        // docs/mobile/local-db-and-sync.md.
        onUpgrade: (Migrator m, int from, int to) async {},
    );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
        File(p.join(directory.path, 'lifelink.sqlite')),
    );
});
