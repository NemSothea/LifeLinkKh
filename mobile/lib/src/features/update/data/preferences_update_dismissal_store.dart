import 'package:shared_preferences/shared_preferences.dart';

import '../domain/update_dismissal_store.dart';

/// The "Later" answer in `SharedPreferences`, beside the language and intro flags: a
/// preference, not a credential.
///
/// Takes an already-loaded [SharedPreferences] so [dismissedVersionCode] stays
/// synchronous — see `UpdateDismissalStore`.
final class PreferencesUpdateDismissalStore implements UpdateDismissalStore {
    PreferencesUpdateDismissalStore(this._preferences);

    /// Namespaced because `SharedPreferences` is one flat map shared with every plugin.
    static const String _key = 'lifelink.update.dismissedVersionCode';

    final SharedPreferences _preferences;

    @override
    int? dismissedVersionCode() => _preferences.getInt(_key);

    @override
    Future<void> dismiss(int versionCode) => _preferences.setInt(_key, versionCode);
}
