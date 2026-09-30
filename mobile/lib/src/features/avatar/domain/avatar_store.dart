import 'avatar_spec.dart';

/// The avatar the user picked, kept on this phone.
///
/// One slot, tagged with the user it belongs to, not one key per user: a shared phone
/// must not collect a list of every account that has signed in on it. When someone else
/// signs in the tag does not match, they see their own default face, and their first pick
/// replaces the slot.
///
/// Synchronous read for the same reason as `LocaleStore` — the backing store is loaded
/// before `runApp`, and the Me tab should not paint the default face for one frame and
/// then swap it.
abstract interface class AvatarStore {
    AvatarSpec? read(String userId);

    Future<void> write(String userId, AvatarSpec spec);
}

/// The default binding: remembers for the life of the process. `main.dart` overrides it
/// with the `SharedPreferences` one.
final class InMemoryAvatarStore implements AvatarStore {
    String? _userId;
    AvatarSpec? _spec;

    @override
    AvatarSpec? read(String userId) => userId == _userId ? _spec : null;

    @override
    Future<void> write(String userId, AvatarSpec spec) async {
        _userId = userId;
        _spec = spec;
    }
}
