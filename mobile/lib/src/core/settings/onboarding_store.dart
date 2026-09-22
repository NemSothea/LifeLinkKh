/// Whether this phone has already been shown the intro.
///
/// An interface for the same reason [LocaleStore] is one: the backing plugin needs a
/// platform channel, so a widget test that touched `SharedPreferences` directly would
/// need `TestDefaultBinaryMessengerBinding` wiring in every file that builds a screen.
///
/// One flag, not a step counter. A donor who quits halfway through three slides has seen
/// enough of them; resuming someone mid-intro two days later is a worse experience than
/// either finishing or skipping it.
abstract interface class OnboardingStore {
    /// Synchronous, like `LocaleStore.read`: the router's redirect runs before the first
    /// frame, and an async read there would paint sign-in and then yank it away.
    bool hasSeenIntro();

    Future<void> markIntroSeen();
}

/// The default binding, and what every widget test gets for free: remembers for the life
/// of the process and nothing longer. `main.dart` overrides it with the real one.
///
/// Defaults to *seen*, which is the opposite of a fresh install on purpose. Every test
/// that boots the app is testing something else — sign-in, a push tap, the dashboard —
/// and none of them should have to dismiss a carousel first. The one test that cares
/// about first launch asks for it with `seen: false`.
final class InMemoryOnboardingStore implements OnboardingStore {
    // `seen: true` reads better at every call site than `_seen: true` would, and the
    // field stays private because it is mutable state rather than configuration.
    // ignore: prefer_initializing_formals
    InMemoryOnboardingStore({bool seen = true}) : _seen = seen;

    bool _seen;

    @override
    bool hasSeenIntro() => _seen;

    @override
    Future<void> markIntroSeen() async => _seen = true;
}
