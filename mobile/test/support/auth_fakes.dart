import 'dart:async';

import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/google_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/session_store.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';
import 'package:lifelink_kh/src/features/home/domain/health_repository.dart';
import 'package:lifelink_kh/src/features/home/domain/health_status.dart';
import 'package:lifelink_kh/src/features/notify/domain/fcm_token_repository.dart';
import 'package:lifelink_kh/src/features/notify/domain/push_token_source.dart';

/// Fakes at every seam the M3 auth flow crosses, so a widget test drives the real
/// `AuthService`, the real controller and the real router with no Firebase, no keystore and
/// no network.
///
/// Shared rather than per-file because the sign-in screen test and the router test need the
/// same set, and two copies would drift.
AuthSession testSession({String token = 'jwt-1', bool isNewAccount = false}) => AuthSession(
    token: token,
    user: AuthUser(
        id: '11111111-1111-1111-1111-111111111111',
        role: UserRole.donor,
        displayName: 'Sothea',
        isNewAccount: isNewAccount,
    ),
);

final class FakeAuthRepository implements AuthRepository {
    Failure? failure;
    int exchangeCount = 0;

    @override
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    }) async {
        exchangeCount++;
        final failure = this.failure;
        if (failure != null) return Failed(failure);
        return Success(testSession());
    }
}

final class FakeSessionStore implements SessionStore {
    FakeSessionStore([this._session]);

    AuthSession? _session;

    AuthSession? get stored => _session;

    @override
    Future<AuthSession?> read() async => _session;

    @override
    Future<void> write(AuthSession session) async => _session = session;

    @override
    Future<void> clear() async => _session = null;
}

final class FakeGoogleCredentials implements GoogleCredentials {
    /// `null` models a dismissed account chooser.
    String? interactiveToken = 'firebase-id-token';
    String? silentToken = 'firebase-id-token';
    bool signedOut = false;

    @override
    Future<String?> signIn() async => interactiveToken;

    @override
    Future<String?> idToken({bool forceRefresh = false}) async => silentToken;

    @override
    Future<void> signOut() async => signedOut = true;
}

final class FakeFcmTokenRepository implements FcmTokenRepository {
    final List<String> registered = [];
    int clearCount = 0;

    @override
    Future<Result<void>> register(String fcmToken) async {
        registered.add(fcmToken);
        return const Success(null);
    }

    @override
    Future<Result<void>> clear() async {
        clearCount++;
        return const Success(null);
    }
}

final class FakePushTokenSource implements PushTokenSource {
    String? token = 'fcm-token-1';
    bool permissionGranted = true;
    final StreamController<String> refreshes = StreamController<String>.broadcast();

    @override
    Future<bool> requestPermission() async => permissionGranted;

    @override
    Future<String?> currentToken() async => token;

    @override
    Stream<String> tokenRefreshes() => refreshes.stream;
}

/// The home screen is behind the redirect, so every router test renders it and therefore
/// needs the health call answered.
final class FakeHealthRepository implements HealthRepository {
    @override
    Future<HealthStatus> fetchStatus() async => const HealthStatus('UP');
}
