import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/facebook_credentials.dart';

/// The real [FacebookCredentials]: Facebook login dialog → Firebase session → Firebase
/// ID token.
///
/// Same shape as `FirebaseGoogleCredentials`, and the same sharp edge: **the token sent
/// to our backend is the Firebase one**, minted by `User.getIdToken()`. The Facebook
/// access token is only the credential used to open the Firebase session — the backend's
/// `GoogleTokenVerifier` verifies a Firebase-issued token regardless of which federated
/// provider created it (FR-AUTH-004 scope: no separate backend verifier for Facebook).
final class FirebaseFacebookCredentials implements FacebookCredentials {
    FirebaseFacebookCredentials({FirebaseAuth? auth, fb.FacebookAuth? facebookAuth})
        : _auth = auth ?? FirebaseAuth.instance,
          _facebook = facebookAuth ?? fb.FacebookAuth.instance;

    final FirebaseAuth _auth;
    final fb.FacebookAuth _facebook;

    @override
    Future<String?> signIn() async {
        final fb.LoginResult result = await _facebook.login(
            permissions: const ['public_profile', 'email'],
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
                final credential = FacebookAuthProvider.credential(token.tokenString);
                final userCredential = await _auth.signInWithCredential(credential);
                // Our session JWT is minted from this, and from nothing the client sends.
                return userCredential.user?.getIdToken();
        }
    }
}
