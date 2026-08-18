/// The Firebase/Google half of sign-in, behind an interface.
///
/// **What the tokens here are.** Both methods return a **Firebase** ID token, not the
/// Google one. Google's token is an implementation detail of getting a Firebase session:
/// the backend calls `FirebaseAuth.verifyIdToken` and checks the issuer is
/// `securetoken.google.com/<our project>`, so a raw Google token would be rejected.
///
/// Firebase Auth holds the Google refresh token in platform storage and mints fresh ID
/// tokens without user interaction — that mechanism, already shipped because FCM needs
/// the Firebase SDK anyway, is why ADR 0007 adds no refresh token of our own.
///
/// Abstract for one concrete reason: the Firebase project does not exist yet
/// (`docs/scope.md`), and the sign-in screen, the service and the 401 repair path all
/// have to be testable before it does.
abstract interface class GoogleCredentials {
    /// Interactive sign-in. Returns the Firebase ID token, or `null` when the user
    /// dismissed the account chooser — a cancel is not an error and must not surface as
    /// one.
    ///
    /// Throws only on a real platform failure.
    Future<String?> signIn();

    /// A Firebase ID token for the already-signed-in account, without any UI.
    ///
    /// [forceRefresh] is what makes ADR 0007's silent repair work: after a 401 the
    /// cached ID token is presumed stale and a fresh one is minted from the refresh token
    /// the Firebase SDK holds in platform storage. Returns `null` when there is no
    /// Firebase user, or when the credential has been revoked — the terminal case that
    /// routes to the sign-in screen. The backend verifies with `checkRevoked = true`, so
    /// revocation is a real 401 and not a theoretical one.
    Future<String?> idToken({bool forceRefresh = false});

    /// Clears the Firebase/Google session on this device. Our JWT is disposed of
    /// separately, via the `SessionStore`.
    Future<void> signOut();
}
