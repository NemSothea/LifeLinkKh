import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/account/application/account_deletion_service.dart';
import 'package:lifelink_kh/src/features/account/data/functions_account_repository.dart';
import 'package:lifelink_kh/src/features/account/domain/account_deletion.dart';
import 'package:lifelink_kh/src/features/account/domain/account_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/reauthentication.dart';

import 'support/auth_fakes.dart';

/// DEC-016's ordering — re-authenticate, call, retry once on a stale sign-in, and only
/// then end the session — with fakes at every seam and no Firebase.
void main() {
    late FakeAccountRepository repository;
    late FakeSessionStore store;
    late FakeGoogleCredentials google;
    late FakeFacebookCredentials facebook;
    late int localClears;

    AccountDeletionService serviceUnder({Future<void> Function()? clearLocalData}) =>
        AccountDeletionService(
            repository: repository,
            sessionStore: store,
            credentials: google,
            facebookCredentials: facebook,
            clearLocalData: clearLocalData ?? () async => localClears++,
        );

    const recentSignIn = Failed<AccountDeletion>(
        ForbiddenFailure(code: AccountRepository.recentSignInRequired),
    );

    void expectNothingChangedLocally() {
        expect(store.stored, isNotNull, reason: 'the account still exists; so must the session');
        expect(google.signedOut, isFalse);
        expect(localClears, 0, reason: 'the account still exists; so does its local data');
    }

    setUp(() {
        repository = FakeAccountRepository();
        store = FakeSessionStore(testSession());
        google = FakeGoogleCredentials();
        facebook = FakeFacebookCredentials();
        localClears = 0;
    });

    test('success re-authenticates first, then clears the session and signs out', () async {
        final result = await serviceUnder().deleteAccount();

        expect(result.valueOrNull, FakeAccountRepository.deletion);
        expect(google.reauthCount, 1);
        expect(repository.calls, 1);
        expect(store.stored, isNull);
        expect(google.signedOut, isTrue);
        expect(localClears, 1, reason: 'SEC-REVIEW-003 F-07: nothing of it stays on the phone');
    });

    test('local data is cleared only after the Firebase sign-out', () async {
        final order = <String>[];
        await serviceUnder(
            clearLocalData: () async => order.add(google.signedOut ? 'after' : 'before'),
        ).deleteAccount();

        expect(order, ['after']);
    });

    test('a local clear that fails is still a successful deletion', () async {
        final result = await serviceUnder(clearLocalData: () async => throw Exception('disk'))
            .deleteAccount();

        expect(result.valueOrNull, FakeAccountRepository.deletion);
        expect(store.stored, isNull);
    });

    test('a Facebook user is re-authenticated with Facebook, not Google', () async {
        google.provider = SignInProvider.facebook;

        await serviceUnder().deleteAccount();

        expect(facebook.reauthCount, 1);
        expect(google.reauthCount, 0);
        expect(repository.calls, 1);
    });

    test('a dismissed re-authentication calls nothing and changes nothing', () async {
        google.reauthOutcomes.add(Reauthentication.cancelled);

        final result = await serviceUnder().deleteAccount();

        expect(result, isA<Success<AccountDeletion?>>());
        expect(result.valueOrNull, isNull);
        expect(repository.calls, 0);
        expectNothingChangedLocally();
    });

    test('RECENT_SIGN_IN_REQUIRED re-authenticates once more and retries once', () async {
        repository.results.add(recentSignIn);

        final result = await serviceUnder().deleteAccount();

        expect(result.valueOrNull, FakeAccountRepository.deletion);
        expect(google.reauthCount, 2);
        expect(repository.calls, 2);
        expect(store.stored, isNull);
    });

    test('a second RECENT_SIGN_IN_REQUIRED is shown, not looped on', () async {
        repository.results.addAll([recentSignIn, recentSignIn, recentSignIn]);

        final result = await serviceUnder().deleteAccount();

        expect(
            (result as Failed<AccountDeletion?>).failure,
            isA<ForbiddenFailure>().having(
                (f) => f.code,
                'code',
                AccountRepository.recentSignInRequired,
            ),
        );
        expect(repository.calls, 2);
        expectNothingChangedLocally();
    });

    test('dismissing the retry\'s re-authentication stops there', () async {
        repository.results.add(recentSignIn);
        google.reauthOutcomes.addAll([Reauthentication.confirmed, Reauthentication.cancelled]);

        final result = await serviceUnder().deleteAccount();

        expect(result.valueOrNull, isNull);
        expect(repository.calls, 1);
        expectNothingChangedLocally();
    });

    test('no network is a NetworkFailure and the session is kept', () async {
        repository.results.add(const Failed(NetworkFailure()));

        final result = await serviceUnder().deleteAccount();

        expect((result as Failed<AccountDeletion?>).failure, isA<NetworkFailure>());
        expect(repository.calls, 1, reason: 'only a stale sign-in is retried');
        expectNothingChangedLocally();
    });

    test('a different account at re-authentication deletes nothing', () async {
        google.reauthOutcomes.add(Reauthentication.differentAccount);

        final result = await serviceUnder().deleteAccount();

        expect(
            (result as Failed<AccountDeletion?>).failure,
            isA<ForbiddenFailure>().having(
                (f) => f.code,
                'code',
                AccountDeletionService.differentAccount,
            ),
        );
        expect(repository.calls, 0);
        expectNothingChangedLocally();
    });

    test('a platform failure while re-authenticating does not escape as an exception', () async {
        google.throwOnReauth = true;

        final result = await serviceUnder().deleteAccount();

        expect((result as Failed<AccountDeletion?>).failure, isA<UnknownFailure>());
        expect(repository.calls, 0);
        expectNothingChangedLocally();
    });

    group('accountFailureFrom — the callable\'s refusals', () {
        test('failed-precondition carries its reason in details.code', () {
            expect(
                accountFailureFrom(
                    code: 'failed-precondition',
                    details: {'code': 'RECENT_SIGN_IN_REQUIRED'},
                ),
                isA<ForbiddenFailure>().having((f) => f.code, 'code', 'RECENT_SIGN_IN_REQUIRED'),
            );
            expect(
                accountFailureFrom(code: 'failed-precondition', details: {'code': 'ADMIN_ACCOUNT'}),
                isA<ForbiddenFailure>().having((f) => f.code, 'code', 'ADMIN_ACCOUNT'),
            );
        });

        test('no connection and no sign-in map like any Firebase error', () {
            expect(accountFailureFrom(code: 'unavailable'), isA<NetworkFailure>());
            expect(accountFailureFrom(code: 'deadline-exceeded'), isA<NetworkFailure>());
            expect(accountFailureFrom(code: 'unauthenticated'), isA<UnauthorizedFailure>());
            expect(accountFailureFrom(code: 'internal'), isA<ServerFailure>());
        });
    });
}
