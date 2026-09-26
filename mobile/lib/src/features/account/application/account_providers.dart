import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/functions_account_repository.dart';
import '../domain/account_repository.dart';
import 'account_deletion_service.dart';

part 'account_providers.g.dart';

/// Singapore, the region every LifeLink Function is deployed to
/// (`setGlobalOptions` in `firebase/functions/src/index.js`). `FirebaseFunctions.instance`
/// would call `us-central1` and get a 404 dressed up as `not-found`.
const String functionsRegion = 'asia-southeast1';

/// A provider rather than `FirebaseFunctions.instanceFor` at the call site, so no widget
/// test reaches a platform channel. `main.dart` points the same instance at the emulator.
@Riverpod(keepAlive: true)
FirebaseFunctions functions(FunctionsRef ref) =>
    FirebaseFunctions.instanceFor(region: functionsRegion);

@Riverpod(keepAlive: true)
AccountRepository accountRepository(AccountRepositoryRef ref) =>
    FunctionsAccountRepository(ref.watch(functionsProvider));

@Riverpod(keepAlive: true)
AccountDeletionService accountDeletionService(AccountDeletionServiceRef ref) =>
    AccountDeletionService(
        repository: ref.watch(accountRepositoryProvider),
        sessionStore: ref.watch(sessionStoreProvider),
        credentials: ref.watch(googleCredentialsProvider),
        facebookCredentials: ref.watch(facebookCredentialsProvider),
    );
