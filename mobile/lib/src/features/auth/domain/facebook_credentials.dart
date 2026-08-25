/// The Facebook half of sign-in, behind an interface — mirrors [GoogleCredentials]'s
/// shape and reason for existing (testable before a real Facebook app exists).
///
/// Session renewal and sign-out are **not** here. Once a Facebook login has opened a
/// Firebase session, `FirebaseAuth.currentUser` behaves identically regardless of which
/// federated provider created it — `GoogleCredentials.idToken`/`signOut` already operate
/// on `currentUser`, not on Google specifically, so `AuthService` keeps using those for
/// both providers rather than duplicating them here.
abstract interface class FacebookCredentials {
    /// Interactive sign-in. Returns the Firebase ID token, or `null` when the user
    /// cancelled the Facebook login dialog — a cancel is not an error and must not
    /// surface as one.
    ///
    /// Throws only on a real platform failure.
    Future<String?> signIn();
}
