import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/portal_api_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/functions_account_repository.dart';
import '../domain/account_repository.dart';
import 'account_deletion_service.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
AccountRepository accountRepository(AccountRepositoryRef ref) =>
    FunctionsAccountRepository(ref.watch(portalApiProvider));

@Riverpod(keepAlive: true)
AccountDeletionService accountDeletionService(AccountDeletionServiceRef ref) =>
    AccountDeletionService(
        repository: ref.watch(accountRepositoryProvider),
        sessionStore: ref.watch(sessionStoreProvider),
        credentials: ref.watch(googleCredentialsProvider),
        facebookCredentials: ref.watch(facebookCredentialsProvider),
    );
