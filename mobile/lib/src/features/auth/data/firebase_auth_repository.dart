// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/user_role.dart';

/// Sign-in with no backend (ADR 0009) — what `POST /auth/google` was.
///
/// By the time this runs the credentials have already signed the user into Firebase, so
/// there is nothing to exchange: the Firebase ID token *is* the session, and Firebase
/// refreshes it. What remains of the old endpoint is the user record — created on the
/// first sign-in, read on every later one — and the rule that a returning user keeps
/// their role, whatever the sign-in screen asked for.
final class FirebaseAuthRepository implements AuthRepository {
    FirebaseAuthRepository(
        this._db, {
        required String? Function() currentUid,
        required String? Function() currentDisplayName,
    })  : _currentUid = currentUid,
          _currentDisplayName = currentDisplayName;

    final FirebaseFirestore _db;
    final String? Function() _currentUid;
    final String? Function() _currentDisplayName;

    @override
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    }) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        // Self-service roles only, as the endpoint enforced: HOSPITAL and ADMIN are claims
        // a Function sets, never something a sign-in screen can ask for.
        final requested = UserRole.selfService.contains(role) ? role : UserRole.donor;
        try {
            final ref = _db.collection('users').doc(uid);
            final existing = (await ref.get()).data();
            final name = _currentDisplayName()?.trim() ?? '';

            if (existing == null) {
                await ref.set({
                    if (name.isNotEmpty) 'displayName': name,
                    'language': 'km',
                    'role': requested.wireValue,
                    'fcmToken': null,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                });
            }

            return Success(AuthSession(
                token: idToken,
                user: AuthUser(
                    id: uid,
                    // The role ignored for a returning user, as `AuthController` documented.
                    role: UserRole.fromWire(existing?['role'] as String?) ?? requested,
                    displayName: (existing?['displayName'] as String?) ?? name,
                    isNewAccount: existing == null,
                ),
            ));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }
}
