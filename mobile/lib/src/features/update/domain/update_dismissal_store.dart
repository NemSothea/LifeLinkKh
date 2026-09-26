/// Which "new version available" notice the user has already said "Later" to.
///
/// One version code, not a list: a dismissal only has to silence the notice until a
/// newer build ships, and a newer build replaces it. Synchronous read for the same reason
/// as `OnboardingStore` — the backing store is loaded before `runApp`.
abstract interface class UpdateDismissalStore {
    int? dismissedVersionCode();

    Future<void> dismiss(int versionCode);
}

/// The default binding: remembers for the life of the process. `main.dart` overrides it
/// with the `SharedPreferences` one.
final class InMemoryUpdateDismissalStore implements UpdateDismissalStore {
    InMemoryUpdateDismissalStore([this._dismissed]);

    int? _dismissed;

    @override
    int? dismissedVersionCode() => _dismissed;

    @override
    Future<void> dismiss(int versionCode) async => _dismissed = versionCode;
}
