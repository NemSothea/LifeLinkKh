import 'package:flutter/foundation.dart';

/// Build-time configuration. Nothing here is committed with a value, and nothing is
/// required: a plain `flutter run` talks to the real `lifelinkkh` Firebase project, whose
/// config the platform files (`google-services.json`, `GoogleService-Info.plist`) carry.
///
/// Every value is an optional override, passed with `--dart-define`:
/// ```
/// flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081 \
///             --dart-define=PORTAL_URL=http://10.0.2.2:3000
/// ```
/// `10.0.2.2` is the Android emulator's alias for the host machine, where the Firebase
/// emulator suite and a local portal listen (ADR 0009, ADR 0010, `firebase/README.md`).
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

    static ({String host, int port})? get firestoreEmulator => _hostPort(_firestoreEmulator);

    /// Where the portal's functions are (ADR 0010): `createRequest`, `respondToMatch`,
    /// `deleteAccount` at `$portalUrl/api/functions/{name}`. The deployed portal by
    /// default; a local `next dev` for a demo against the emulators.
    static const String _portalUrl = String.fromEnvironment(
        'PORTAL_URL',
        defaultValue: defaultPortalUrl,
    );

    static const String defaultPortalUrl = 'https://lifelinkkh.vercel.app';

    static String get portalUrl => portalUrlFrom(_portalUrl, allowHttp: kDebugMode);

    /// `raw` if the app may send an ID token there, else [defaultPortalUrl].
    ///
    /// `http://` only in a debug build (SEC-REVIEW-003 F-15): the demo's
    /// `flutter run --dart-define=PORTAL_URL=http://10.0.2.2:3000` has no TLS to offer, but
    /// a release build posting a bearer token in clear text would hand it to anyone on the
    /// café Wi-Fi. A release built with an http URL talks to the deployed portal instead —
    /// a wrong server is a visible bug, a leaked token is not.
    @visibleForTesting
    static String portalUrlFrom(String raw, {required bool allowHttp}) {
        final uri = Uri.tryParse(raw.trim());
        if (uri == null || uri.host.isEmpty) return defaultPortalUrl;
        if (uri.isScheme('https') || (allowHttp && uri.isScheme('http'))) return raw.trim();
        return defaultPortalUrl;
    }

    static ({String host, int port})? _hostPort(String value) {
        final parts = value.split(':');
        if (parts.length != 2) return null;
        final port = int.tryParse(parts[1]);
        return port == null ? null : (host: parts[0], port: port);
    }
}
