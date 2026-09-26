/// Build-time configuration. Nothing here is committed with a value, and nothing is
/// required: a plain `flutter run` talks to the real `lifelinkkh` Firebase project, whose
/// config the platform files (`google-services.json`, `GoogleService-Info.plist`) carry.
///
/// Both values are optional overrides, passed with `--dart-define`:
/// ```
/// flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081
/// ```
/// `10.0.2.2` is the Android emulator's alias for the host machine, where the Firebase
/// emulator suite listens (ADR 0009, `firebase/README.md`).
class Env {
    Env._();

    static const String _googleServerClientId =
        String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

    /// The OAuth **web** client id, for builds that cannot carry
    /// `android/app/google-services.json`.
    ///
    /// Normally null: the `google-services` Gradle plugin generates a
    /// `default_web_client_id` resource from that file and `google_sign_in` uses it. Not a
    /// secret either way — it is restricted by package name and SHA-1 fingerprint.
    static String? get googleServerClientId =>
        _googleServerClientId.isEmpty ? null : _googleServerClientId;

    /// `host:port` of a Firestore emulator, e.g. `10.0.2.2:8081` from the Android emulator.
    /// Unset is the real `lifelinkkh` project. ADR 0009 — `firebase/README.md` starts one.
    static const String _firestoreEmulator = String.fromEnvironment('FIRESTORE_EMULATOR');

    static ({String host, int port})? get firestoreEmulator {
        final parts = _firestoreEmulator.split(':');
        if (parts.length != 2) return null;
        final port = int.tryParse(parts[1]);
        return port == null ? null : (host: parts[0], port: port);
    }
}
