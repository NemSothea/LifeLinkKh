/// The Google half of sign-in, behind an interface.
///
/// Firebase Auth holds the Google refresh token in platform storage and mints fresh ID
/// tokens without user interaction — that mechanism, already shipped because FCM needs
/// the Firebase SDK anyway, is why ADR 0007 adds no refresh token of our own.
///
/// Abstract for one concrete reason: the Firebase project does not exist yet
/// (`docs/scope.md`), and the sign-in screen, the service and the 401 repair path all
/// have to be testable before it does.
abstract interface class GoogleCredentials {
    /// Interactive sign-in. Returns the Google ID token, or `null` when the user
    /// dismissed the account chooser — a cancel is not an error and must not surface as
    /// one.
    ///
    /// Throws only on a real platform failure.
    Future<String?> signIn();

    /// A Google ID token for the already-signed-in account, without any UI.
    ///
    /// [forceRefresh] is what makes ADR 0007's silent repair work: after a 401 the
    /// cached ID token is presumed stale and a fresh one is minted. Returns `null` when
    /// there is no Firebase user, or when Google access has been revoked — the terminal
    /// case that routes to the sign-in screen.
    Future<String?> idToken({bool forceRefresh = false});

    /// Clears the Firebase/Google session on this device. Our JWT is disposed of
    /// separately, via the `SessionStore`.
    Future<void> signOut();
}
