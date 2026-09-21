import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'database_providers.g.dart';

/// One database for the whole app, opened once.
///
/// `keepAlive` because a SQLite connection that closes when the last screen
/// watching it disposes would reopen on the next donor action — and the queue
/// has to outlive every screen, since its whole job is to finish work the user
/// already walked away from.
///
/// Tests override this with `AppDatabase.memory()`.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
    final database = AppDatabase();
    ref.onDispose(database.close);
    return database;
}
