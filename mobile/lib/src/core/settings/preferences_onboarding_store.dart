import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_store.dart';

/// The intro flag in `SharedPreferences`, next to the language choice and for the same
/// reason: it is a preference, not a credential, and nothing about "this phone has seen
/// three slides" is worth a Keystore round-trip (ADR 0007 keeps that for the session).
///
/// Takes an already-loaded [SharedPreferences] rather than calling `getInstance()`, so
/// [hasSeenIntro] can stay synchronous — see `OnboardingStore`.
final class PreferencesOnboardingStore implements OnboardingStore {
    PreferencesOnboardingStore(this._preferences);

    /// Namespaced because `SharedPreferences` is one flat map shared with every plugin in
    /// the app.
    static const String _key = 'lifelink.onboarding.seen';

    final SharedPreferences _preferences;

    /// A missing key is a fresh install, which is exactly when the intro should show.
    @override
    bool hasSeenIntro() => _preferences.getBool(_key) ?? false;

    @override
    Future<void> markIntroSeen() => _preferences.setBool(_key, true);
}
