import 'avatar_spec.dart';

/// The picked avatar on the user's account, beside the copy `AvatarStore` keeps on the
/// phone. The phone's copy is gone after a reinstall or on another phone; this one is what
/// brings the face back there.
///
/// Neither method throws: the avatar is a nicety, and a failed read or write must never
/// cost the Me tab or a sign-in.
abstract interface class AvatarAccount {
    /// Null when nothing was picked, the account has no user doc yet, or the read failed.
    Future<AvatarSpec?> fetch(String userId);

    Future<void> save(String userId, AvatarSpec spec);
}

/// The default binding: no account at all. `main.dart` overrides it with the Firestore one,
/// so no widget test that builds the Me tab reaches Firebase.
final class NoAvatarAccount implements AvatarAccount {
    const NoAvatarAccount();

    @override
    Future<AvatarSpec?> fetch(String userId) async => null;

    @override
    Future<void> save(String userId, AvatarSpec spec) async {}
}
