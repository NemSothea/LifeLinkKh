import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/google_credentials.dart';

/// The real [GoogleCredentials]: Google account chooser → Firebase session → Firebase
/// ID token.
///
/// Three sharp edges, all of them silent failures if got wrong:
///
/// 1. **The token sent to our backend is the Firebase one**, minted by
///    `User.getIdToken()`. The Google ID token is only the credential used to open the
///    Firebase session; our verifier would reject it on the issuer check.
/// 2. **A cancelled account chooser is a `GoogleSignInException` in google_sign_in 7**,
///    not a `null` return. Letting it propagate would render "sign-in failed" every time
///    a user changes their mind.
/// 3. **`idToken` comes back null when the app is misconfigured** — missing
///    `serverClientId` / `default_web_client_id`, or a debug SHA-1 that is not registered
///    in the Firebase console. `docs/scope.md` calls this the single most common wasted
///    afternoon on a project of this shape, so it throws with the diagnosis rather than
///    returning null and looking like a cancel.
final class FirebaseGoogleCredentials implements GoogleCredentials {
    FirebaseGoogleCredentials({
        FirebaseAuth? auth,
        GoogleSignIn? googleSignIn,
        this.serverClientId,
    })  : _auth = auth ?? FirebaseAuth.instance,
          _google = googleSignIn ?? GoogleSignIn.instance;

    final FirebaseAuth _auth;
    final GoogleSignIn _google;

    /// The OAuth **web** client id from the Firebase console.
    ///
    /// Normally left null: the `com.google.gms.google-services` Gradle plugin turns
    /// `google-services.json` into a `default_web_client_id` resource and the plugin picks
    /// it up. Overridable by `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` for a build that
    /// cannot carry the JSON.
    final String? serverClientId;

    Future<void>? _initialization;

    /// `initialize()` must run once before any other call, and exactly once. Caching the
    /// future rather than a bool makes two concurrent callers await the same
    /// initialisation instead of racing it.
    Future<void> _ensureInitialized() =>
        _initialization ??= _google.initialize(serverClientId: serverClientId);

    @override
    Future<String?> signIn() async {
        await _ensureInitialized();

        final GoogleSignInAccount account;
        try {
            account = await _google.authenticate();
        } on GoogleSignInException catch (error) {
            if (error.code == GoogleSignInExceptionCode.canceled) return null;
            // Anything else is a real failure — misconfiguration, no activity, or an
            // interrupted flow. The service above turns it into a Failure; it must not be
            // mistaken for a cancel.
            rethrow;
        }

        final googleIdToken = account.authentication.idToken;
        if (googleIdToken == null) {
            throw StateError(
                'Google returned no ID token. The usual cause is a missing '
                'serverClientId/default_web_client_id, or a debug SHA-1 fingerprint that '
                'is not registered on the Android app in the Firebase console.',
            );
        }

        final credentials = await _auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: googleIdToken),
        );
        // Our session JWT is minted from this, and from nothing the client sends.
        return credentials.user?.getIdToken();
    }

    @override
    Future<String?> idToken({bool forceRefresh = false}) async {
        final user = _auth.currentUser;
        if (user == null) return null;
        try {
            return await user.getIdToken(forceRefresh);
        } on FirebaseAuthException catch (_) {
            // `user-token-expired`, `user-disabled`, `user-not-found` — the credential is
            // gone. Terminal by ADR 0007, so null rather than a throw.
            return null;
        }
    }

    @override
    Future<void> signOut() async {
        await _ensureInitialized();
        // Google first: signing out of Firebase alone leaves the account chooser
        // pre-answered, so the next sign-in silently reuses the account the user just left.
        await _google.signOut();
        await _auth.signOut();
    }
}
