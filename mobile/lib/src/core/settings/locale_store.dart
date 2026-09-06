import 'dart:ui' show Locale;

/// Where the app's language choice lives between launches.
///
/// An interface rather than a direct `SharedPreferences` call for the same reason
/// `SessionStore` is one: the plugin needs a platform channel, so a widget test that
/// touched it directly would need `TestDefaultBinaryMessengerBinding` wiring in every
/// file that builds a screen.
abstract interface class LocaleStore {
    /// The stored choice, or null when nobody has picked one yet — a null is "follow
    /// the app's own default", not an error.
    ///
    /// Synchronous on purpose: `MaterialApp.locale` is read on the first frame, and an
    /// async read there means the app paints one frame in the wrong language before
    /// correcting itself. The cost is that the backing store has to be loaded before
    /// `runApp` (see `main.dart`).
    Locale? read();

    Future<void> write(Locale locale);
}

/// The default binding, and what every widget test gets for free: remembers a choice
/// for the life of the process and nothing longer. `main.dart` overrides it with the
/// real one.
final class InMemoryLocaleStore implements LocaleStore {
    InMemoryLocaleStore([this._locale]);

    Locale? _locale;

    @override
    Locale? read() => _locale;

    @override
    Future<void> write(Locale locale) async => _locale = locale;
}
