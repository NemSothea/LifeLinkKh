import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/notify/data/firestore_fcm_token_repository.dart';

/// `users/{uid}` as the push token's home (ADR 0009) — where `onRequestCreated` reads
/// `fcmToken` and `language`.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirestoreFcmTokenRepository repository;

    setUp(() {
        db = FakeFirebaseFirestore();
        uid = 'donor-1';
        repository = FirestoreFcmTokenRepository(
            db,
            currentUid: () => uid,
            currentDisplayName: () => ' Nem Sothea ',
        );
    });

    Future<Map<String, dynamic>> user() async => (await db.doc('users/donor-1').get()).data()!;

    test('the first registration creates the user document the rules expect', () async {
        expect(await repository.register('token-1', language: 'en'), isA<Success<void>>());
        final stored = await user();
        expect(stored, containsPair('fcmToken', 'token-1'));
        expect(stored, containsPair('language', 'en'));
        expect(stored, containsPair('role', 'DONOR'));
        expect(stored, containsPair('displayName', 'Nem Sothea'));
        expect(stored.keys, containsAll(<String>['createdAt', 'updatedAt']));
    });

    test('with no language, a new user starts in Khmer', () async {
        await repository.register('token-1');
        expect((await user())['language'], 'km');
    });

    test('a rotation replaces the token and keeps everything else', () async {
        await repository.register('token-1', language: 'en');
        final createdAt = (await user())['createdAt'];
        await repository.register('token-2');
        final stored = await user();
        expect(stored['fcmToken'], 'token-2');
        // Absent language means "leave it", as the endpoint did.
        expect(stored['language'], 'en');
        expect(stored['createdAt'], createdAt);
    });

    test('sign-out clears the token, so the next request does not push this device', () async {
        await repository.register('token-1');
        await repository.clear();
        expect((await user())['fcmToken'], isNull);
    });

    test('clearing with no user document or no user is a no-op, not a failure', () async {
        expect(await repository.clear(), isA<Success<void>>());
        uid = null;
        expect(await repository.clear(), isA<Success<void>>());
    });

    test('registering signed out is UnauthorizedFailure', () async {
        uid = null;
        final result = await repository.register('token-1');
        expect((result as Failed<void>).failure, isA<UnauthorizedFailure>());
    });
}
