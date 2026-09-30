import 'package:shared_preferences/shared_preferences.dart';

import '../domain/avatar_spec.dart';
import '../domain/avatar_store.dart';

/// The picked avatar in `SharedPreferences`, beside the language: a preference, not a
/// credential. Takes an already-loaded [SharedPreferences] so [read] stays synchronous —
/// see `AvatarStore`.
final class PreferencesAvatarStore implements AvatarStore {
    PreferencesAvatarStore(this._preferences);

    /// Namespaced because `SharedPreferences` is one flat map shared with every plugin.
    static const String _ownerKey = 'lifelink.avatar.owner';
    static const String _specKey = 'lifelink.avatar.spec';

    final SharedPreferences _preferences;

    @override
    AvatarSpec? read(String userId) {
        if (_preferences.getString(_ownerKey) != userId) return null;
        return AvatarSpec.decode(_preferences.getString(_specKey));
    }

    @override
    Future<void> write(String userId, AvatarSpec spec) async {
        await _preferences.setString(_ownerKey, userId);
        await _preferences.setString(_specKey, spec.encode());
    }
}
