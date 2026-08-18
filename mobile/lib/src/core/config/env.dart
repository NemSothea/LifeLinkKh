/// Build-time configuration. Nothing here is committed with a value.
///
/// Pass the base URL when running:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
/// ```
/// `10.0.2.2` is the Android emulator's alias for the host machine, which is where
/// docker-compose publishes the backend.
class Env {
    Env._();

    static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

    /// Throws instead of falling back to a default. A silent default is worse than a
    /// crash here: the app would appear to work while pointing at nothing, and the
    /// failure would surface later as an unexplained network error.
    static String get apiBaseUrl {
        if (_apiBaseUrl.isEmpty) {
            throw StateError(
                'API_BASE_URL is not set. Run with '
                '--dart-define=API_BASE_URL=http://10.0.2.2:8080/api '
                '(10.0.2.2 is the host machine as seen from the Android emulator).',
            );
        }
        return _apiBaseUrl;
    }

    /// Lets UI decide what to show without triggering the throw above.
    static bool get isConfigured => _apiBaseUrl.isNotEmpty;

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
}
