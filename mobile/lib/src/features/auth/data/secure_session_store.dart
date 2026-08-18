import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/session_store.dart';
import '../domain/user_role.dart';

/// The session JWT in the Android Keystore / iOS Keychain (ADR 0007).
///
/// Not `SharedPreferences`. The token is a bearer credential with a one-hour life and no
/// server-side revocation, so anything that can read it can act as the donor for that
/// hour — and there is no way to cut it short.
final class SecureSessionStore implements SessionStore {
    SecureSessionStore({FlutterSecureStorage? storage})
        : _storage = storage ?? const FlutterSecureStorage();

    final FlutterSecureStorage _storage;

    /// One key holding the whole session. Two keys would allow a half-written state where
    /// a token exists with no user, and every read would have to handle it.
    static const String _key = 'lifelink.session';

    @override
    Future<AuthSession?> read() async {
        final String? raw;
        try {
            raw = await _storage.read(key: _key);
        } on Object catch (_) {
            // A keystore that cannot be read (restored backup, changed lock screen, OEM
            // bug) is a signed-out app, not a crash on launch. ADR 0007 then silently
            // re-authenticates through the Firebase SDK and the donor sees nothing.
            return null;
        }
        if (raw == null) return null;

        try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            final token = json['token'] as String?;
            final role = UserRole.fromWire(json['role'] as String?);
            final id = json['id'] as String?;
            if (token == null || role == null || id == null) return null;
            return AuthSession(
                token: token,
                user: AuthUser(
                    id: id,
                    role: role,
                    displayName: json['displayName'] as String? ?? '',
                    // Never persisted as true: it describes one sign-in response, not the
                    // account. Restoring it would send a returning donor back through setup.
                    isNewAccount: false,
                ),
            );
        } on FormatException catch (_) {
            // Written by an older build with a different shape. Treated as signed out.
            return null;
        }
    }

    @override
    Future<void> write(AuthSession session) => _storage.write(
        key: _key,
        value: jsonEncode({
            'token': session.token,
            'id': session.user.id,
            'role': session.user.role.wireValue,
            'displayName': session.user.displayName,
        }),
    );

    @override
    Future<void> clear() => _storage.delete(key: _key);
}
