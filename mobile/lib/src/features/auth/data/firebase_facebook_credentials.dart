import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/facebook_credentials.dart';
import '../domain/reauthentication.dart';
import 'firebase_google_credentials.dart' show reauthenticateFirebaseUser;

/// The real [FacebookCredentials]: Facebook login dialog → Firebase session → Firebase
/// ID token.
///
/// Same shape as `FirebaseGoogleCredentials`, and the same sharp edge: **the token
/// returned is the Firebase one**, minted by `User.getIdToken()`. The Facebook access
/// token is only the credential used to open the Firebase session, and from there on a
/// Facebook user is a Firebase user like any other (FR-AUTH-004 scope).
///
/// **Two token shapes.** Android returns a classic Graph access token. iOS, since the
/// SDK's Limited Login (and this plugin's default `LoginTracking.limited`), returns an
/// OIDC *ID token* instead — handing that to `FacebookAuthProvider.credential` fails,
/// because Firebase tries it against the Graph API as an access token. A limited token
/// goes in as `OAuthProvider('facebook.com')` with the raw nonce whose SHA-256 was sent to
/// the login dialog, the same pattern as Sign in with Apple.
final class FirebaseFacebookCredentials implements FacebookCredentials {
    FirebaseFacebookCredentials({FirebaseAuth? auth, fb.FacebookAuth? facebookAuth})
        : _auth = auth ?? FirebaseAuth.instance,
          _facebook = facebookAuth ?? fb.FacebookAuth.instance;

    final FirebaseAuth _auth;
    final fb.FacebookAuth _facebook;

    @override
    Future<String?> signIn() async {
        final credential = await _login();
        if (credential == null) return null;
        final userCredential = await _auth.signInWithCredential(credential);
        // Our session JWT is minted from this, and from nothing the client sends.
        return userCredential.user?.getIdToken();
    }

    @override
    Future<Reauthentication> reauthenticate() async {
        final user = await _auth.authStateChanges().first;
        if (user == null) throw StateError('No Firebase user to re-authenticate.');

        // Facebook may answer from its own cached login without showing a dialog; that
        // is still a Facebook-issued token for this person, and Firebase's
        // re-authentication is what stamps the new auth_time.
        final credential = await _login();
        if (credential == null) return Reauthentication.cancelled;
        return reauthenticateFirebaseUser(user, credential);
    }

    /// The login dialog, turned into a Firebase credential. Null is a cancel.
    Future<AuthCredential?> _login() async {
        final rawNonce = _randomNonce();
        final fb.LoginResult result = await _facebook.login(
            // `public_profile` only. The app never reads a donor's email — the profile shows the
            // name, and Firebase keys the account on the Facebook user id — and asking for
            // `email` needs that permission added to the Meta app's Login use case, without
            // which the web dialog stops at "Invalid Scopes: email".
            permissions: const ['public_profile'],
            loginBehavior: _loginBehavior,
            nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );

        switch (result.status) {
            case fb.LoginStatus.cancelled:
                return null;
            case fb.LoginStatus.failed:
                throw StateError('Facebook login failed: ${result.message}');
            case fb.LoginStatus.operationInProgress:
                throw StateError('Facebook login already in progress');
            case fb.LoginStatus.success:
                final token = result.accessToken;
                if (token == null) {
                    throw StateError('Facebook login succeeded with no access token.');
                }
                return facebookCredentialFor(token, rawNonce: rawNonce);
        }
    }
}

/// Android logs in through a browser tab, not the installed Facebook app.
///
/// The Facebook app's native login ("proxy auth") refuses any caller whose package name is
/// not registered on the Meta app — `(#408) The proxied app is not already installed` —
/// and the Meta dashboard will only save a package name it can find on Google Play. Until
/// LifeLink is published there, the browser flow is the one that works: it needs the App
/// ID and the key hash, both registered, and a phone already signed in to Facebook in its
/// browser still gets a one-tap Continue. Switch back to `nativeWithFallback` once the
/// Play listing exists and the package name is saved on the Meta app.
///
/// iOS is unaffected: its SDK never proxies through the Facebook app for Limited Login.
fb.LoginBehavior get _loginBehavior =>
    Platform.isAndroid ? fb.LoginBehavior.webOnly : fb.LoginBehavior.nativeWithFallback;

/// Which Firebase credential a Facebook token opens. Public for the test: it is the one
/// branch in this file that does not need a platform channel.
AuthCredential facebookCredentialFor(fb.AccessToken token, {required String rawNonce}) =>
    switch (token.type) {
        fb.AccessTokenType.limited => OAuthProvider('facebook.com').credential(
            idToken: token.tokenString,
            rawNonce: rawNonce,
        ),
        fb.AccessTokenType.classic => FacebookAuthProvider.credential(token.tokenString),
    };

/// 32 characters from a CSPRNG. It only has to be unguessable for the life of one login.
String _randomNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
