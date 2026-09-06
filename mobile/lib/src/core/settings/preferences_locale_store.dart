import 'dart:ui' show Locale;

import 'package:shared_preferences/shared_preferences.dart';

import 'locale_store.dart';

/// The language choice in `SharedPreferences` — plain app storage, unlike the session
/// JWT next door in the Keystore (ADR 0007). A language is not a credential; reading it
/// off a rooted device tells an attacker nothing they could not tell by looking at the
/// screen.
///
/// Takes an already-loaded [SharedPreferences] instead of calling `getInstance()`
/// itself, so [read] can stay synchronous — see `LocaleStore.read`.
final class PreferencesLocaleStore implements LocaleStore {
    PreferencesLocaleStore(this._preferences);

    /// Namespaced because `SharedPreferences` is one flat map shared with every plugin
    /// in the app.
    static const String _key = 'lifelink.locale';

    final SharedPreferences _preferences;

    @override
    Locale? read() {
        final code = _preferences.getString(_key);
        // An empty string would produce `Locale('')`, which resolves to nothing and
        // silently falls back — treat it as "not set" like a missing key.
        return (code == null || code.isEmpty) ? null : Locale(code);
    }

    @override
    Future<void> write(Locale locale) => _preferences.setString(_key, locale.languageCode);
}
