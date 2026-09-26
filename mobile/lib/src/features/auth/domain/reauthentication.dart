/// What asking the user to sign in again, right before something irreversible, came to.
///
/// DEC-016: the `deleteAccount` Function refuses an ID token whose `auth_time` is more than
/// five minutes old, so a phone left unlocked on a table cannot erase its owner's account.
/// Re-authenticating on the *existing* Firebase user is what refreshes `auth_time` — a
/// fresh `signInWithCredential` would not do, because it happily switches to whichever
/// account was picked and the deletion would then land on someone else.
enum Reauthentication {
    /// The same person signed in again; `auth_time` is now.
    confirmed,

    /// The account chooser or login dialog was dismissed. Not a failure — the user
    /// changed their mind, and nothing may happen.
    cancelled,

    /// A different Google or Facebook account was picked than the one this Firebase user
    /// belongs to. Firebase refuses it (`user-mismatch`), and so do we: the screen says
    /// which account to choose rather than "something went wrong".
    differentAccount,

    /// Firebase could not be reached to check the credential. Said as "no connection",
    /// because that is what it is and the fix is the same as for the deletion itself.
    networkUnavailable,
}

/// The federated provider the signed-in Firebase user came from — which dialog a
/// re-authentication has to open. FR-AUTH-004 offers exactly these two.
enum SignInProvider { google, facebook }
