import 'reauthentication.dart';

/// The Firebase/Google half of sign-in, behind an interface.
///
/// **What the token here is.** [signIn] returns a **Firebase** ID token, not the Google
/// one. Google's token is an implementation detail of getting a Firebase session, and the
/// Firebase session is what Firestore's Security Rules see (ADR 0009).
///
/// Firebase Auth holds the Google refresh token in platform storage and mints fresh ID
/// tokens without user interaction, so the app keeps no refresh token of its own.
///
/// Abstract so the sign-in screen, the service and session restore are all testable
/// without a Firebase project or a platform channel.
abstract interface class GoogleCredentials {
    /// Interactive sign-in. Returns the Firebase ID token, or `null` when the user
    /// dismissed the account chooser — a cancel is not an error and must not surface as
    /// one.
    ///
    /// Throws only on a real platform failure.
    Future<String?> signIn();

    /// The uid of the Firebase user signed in on this device, or `null` when there is
    /// none. Session restore checks the stored session against it: a session Firebase
    /// does not back cannot read anything.
    Future<String?> currentUid();

    /// Clears the Firebase/Google session on this device. The stored session is
    /// disposed of separately, via the `SessionStore`.
    Future<void> signOut();

    /// Which provider the signed-in Firebase user signed in with, or `null` when there is
    /// no such user or it came from neither (an emulator test account). Here rather than
    /// on a separate interface for the same reason [currentUid] is: it is a question about
    /// the Firebase user, and this is the class that owns it.
    Future<SignInProvider?> currentProvider();

    /// Opens the Google account chooser again and re-authenticates the **current**
    /// Firebase user with it (DEC-016), so the next ID token carries a fresh `auth_time`.
    ///
    /// Throws only on a real platform failure; a dismissed chooser and a different
    /// account are answers, not errors.
    Future<Reauthentication> reauthenticate();
}
