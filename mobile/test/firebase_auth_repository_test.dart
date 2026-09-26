import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/data/firebase_auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';

/// Sign-in with no backend (ADR 0009): the Firebase ID token is the session, and the
/// user record is `users/{uid}` — the counterpart of `dio_auth_repository_test.dart`.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirebaseAuthRepository repository;

    setUp(() {
        db = FakeFirebaseFirestore();
        uid = 'sothea';
        repository = FirebaseAuthRepository(db, currentUid: () => uid, currentDisplayName: () => 'Nem Sothea');
    });

    Future<AuthSession> signIn([UserRole role = UserRole.donor]) async =>
        (await repository.exchangeGoogleToken(idToken: 'firebase-id-token', role: role) as Success<AuthSession>).value;

    test('first sign-in creates the user record and is a new account', () async {
        final session = await signIn(UserRole.requester);
        expect(session.token, 'firebase-id-token');
        expect(session.user.id, 'sothea');
        expect(session.user.role, UserRole.requester);
        expect(session.user.isNewAccount, isTrue);
        final stored = (await db.doc('users/sothea').get()).data()!;
        expect(stored, containsPair('role', 'REQUESTER'));
        expect(stored, containsPair('language', 'km'));
        expect(stored, containsPair('displayName', 'Nem Sothea'));
    });

    test('a returning user keeps their role, whatever the screen asked for', () async {
        await signIn(UserRole.requester);
        final again = await signIn(UserRole.donor);
        expect(again.user.role, UserRole.requester);
        expect(again.user.isNewAccount, isFalse);
    });

    test('a staff role cannot be asked for — it falls back to donor', () async {
        expect((await signIn(UserRole.admin)).user.role, UserRole.donor);
        expect((await db.doc('users/sothea').get()).get('role'), 'DONOR');
    });

    test('no Firebase user is UnauthorizedFailure', () async {
        uid = null;
        final result = await repository.exchangeGoogleToken(idToken: 'x', role: UserRole.donor);
        expect((result as Failed<AuthSession>).failure, isA<UnauthorizedFailure>());
    });
}
