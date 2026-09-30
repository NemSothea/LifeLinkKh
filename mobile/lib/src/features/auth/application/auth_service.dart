// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/facebook_credentials.dart';
import '../domain/google_credentials.dart';
import '../domain/session_store.dart';
import '../domain/user_role.dart';

/// The feature's Service (Week 3, S1–S6): everything that knows how a session is created,
/// restored and ended.
///
/// No Flutter import and no Riverpod import (S5) — the providers in this directory are
/// the only Riverpod-aware code. That is what makes the restore and sign-out ordering
/// below testable with `flutter test` and no emulator.
final class AuthService {
    AuthService({
        required AuthRepository repository,
        required SessionStore sessionStore,
        required GoogleCredentials credentials,
        required FacebookCredentials facebookCredentials,
        Future<void> Function()? clearPushRegistration,
        Future<void> Function()? clearLocalData,
    })  : _repository = repository,
          _sessionStore = sessionStore,
          _credentials = credentials,
          _facebookCredentials = facebookCredentials,
          _clearPushRegistration = clearPushRegistration,
          _clearLocalData = clearLocalData;

    final AuthRepository _repository;
    final SessionStore _sessionStore;
    final GoogleCredentials _credentials;
    final FacebookCredentials _facebookCredentials;

    /// Clears `users/{uid}.fcmToken`, injected as a callback rather than as a repository
    /// so this feature does not import the notify feature's domain.
    final Future<void> Function()? _clearPushRegistration;

    /// Drops what this phone cached for the user — the Drift tables, the Firestore
    /// offline cache, the FCM token (`LocalDataEraser`, SEC-REVIEW-003 F-07). A callback
    /// for the same reason as [_clearPushRegistration].
    final Future<void> Function()? _clearLocalData;

    /// Interactive sign-in, for the sign-in screen.
    ///
    /// `Success(null)` means the user dismissed the Google account chooser. A cancel is
    /// not a failure and must not render as an error — that distinction is why the
    /// success type is nullable rather than the whole call returning a `Failure`.
    Future<Result<AuthSession?>> signIn({UserRole role = UserRole.donor}) =>
        _signInWith(_credentials.signIn, role: role, failureMessage: 'Google sign-in failed');

    /// Interactive sign-in via Facebook, for the sign-in screen's second button
    /// (FR-AUTH-004). Same contract as [signIn] — `Success(null)` means the user
    /// dismissed the Facebook login dialog.
    Future<Result<AuthSession?>> signInWithFacebook({UserRole role = UserRole.donor}) =>
        _signInWith(
            _facebookCredentials.signIn,
            role: role,
            failureMessage: 'Facebook sign-in failed',
        );

    /// Shared by [signIn] and [signInWithFacebook]: both end in a Firebase session, and
    /// the repository turns that into the `users/{uid}` record the same way whichever
    /// federated provider opened it (FR-AUTH-004 scope).
    Future<Result<AuthSession?>> _signInWith(
        Future<String?> Function() obtainIdToken, {
        required UserRole role,
        required String failureMessage,
    }) async {
        assert(
            UserRole.selfService.contains(role),
            'only DONOR and REQUESTER may be requested at sign-up; the server answers '
            '422 ROLE_NOT_SELF_SERVICE for anything else (TM-AUTH-001 E1)',
        );

        final String? idToken;
        try {
            idToken = await obtainIdToken();
        } on Object catch (error) {
            // A platform-channel failure from the Google/Facebook/Firebase plugin. Not a
            // domain failure and not something a message from us can explain — but the
            // developer needs the cause, which is otherwise lost here (a Meta console
            // misconfiguration and a rejected Firebase credential look identical).
            if (kDebugMode) debugPrint('$failureMessage: $error');
            return Failed(UnknownFailure(message: failureMessage));
        }
        if (idToken == null) return const Success(null);

        final result = await _repository.exchangeGoogleToken(
            idToken: idToken,
            role: role,
        );
        return switch (result) {
            Success(value: final session) => await _store(session),
            Failed(failure: final failure) => Failed(failure),
        };
    }

    /// The stored session, if this install has one **and** Firebase agrees. Called at
    /// startup.
    ///
    /// Since ADR 0009 the stored session is only a cache of who signed in; every read and
    /// write is authorised by the Firebase user instead. A session restored without one —
    /// Firebase signed out underneath us, the app data half-cleared, or a session written
    /// by the pre-Firebase build under a backend user id — would show Home and then fail
    /// every Firestore read until the donor found sign-out. So a stored session counts
    /// only when the Firebase uid exists and is the one it was written for; anything else
    /// is cleared and the router lands on sign-in.
    Future<AuthSession?> restoreSession() async {
        final session = await _sessionStore.read();
        if (session == null) return null;

        final String? uid;
        try {
            uid = await _credentials.currentUid();
        } on Object catch (_) {
            // The SDK could not answer. Treated as no Firebase user: signing in again is
            // recoverable, a Home that cannot read anything is not.
            await _sessionStore.clear();
            return null;
        }
        if (uid == session.user.id) return session;

        await _sessionStore.clear();
        if (uid != null) {
            // A *different* Firebase user. Signed out too, so the sign-in screen starts
            // from the account chooser rather than beside someone else's credential.
            try {
                await _credentials.signOut();
            } on Object catch (_) {
                // The stored session is already gone; sign-in still works from here.
            }
        }
        return null;
    }

    /// The most any one network step of sign-out may take. Past it the step is abandoned
    /// and sign-out carries on: someone who tapped "Sign out" on a bad connection should
    /// reach the sign-in screen in seconds, not wait on a server that is not answering.
    static const Duration networkStepTimeout = Duration(seconds: 4);

    /// Signs out of everything, in the order that matters.
    ///
    /// Push registration is cleared **first**, while the Firebase user whose rules allow
    /// the write is still signed in. Signing out first would leave the device registered
    /// for urgent-request alerts with no way left to unregister it.
    ///
    /// Local data goes **last**, and even when the Firebase sign-out throws: clearing the
    /// Firestore cache terminates the instance, which the push-token write above still
    /// needed.
    Future<void> signOut() async {
        try {
            // Bounded: a Firestore write resolves only when the server acknowledges it, so
            // on a dead connection this await never returns and sign-out hung with it.
            await _clearPushRegistration?.call().timeout(networkStepTimeout);
        } on Object catch (_) {
            // Deliberately swallowed. A user who asked to sign out is signed out even if
            // the network is down; a stale token costs at most an alert this phone
            // should no longer get.
        }
        await _sessionStore.clear();
        try {
            await _credentials.signOut();
        } finally {
            await _eraseLocalData();
        }
    }

    Future<void> _eraseLocalData() async {
        try {
            await _clearLocalData?.call();
        } on Object catch (_) {
            // `LocalDataEraser` does not throw; a sign-out does not depend on that.
        }
    }

    Future<Result<AuthSession?>> _store(AuthSession session) async {
        await _sessionStore.write(session);
        return Success(session);
    }
}
