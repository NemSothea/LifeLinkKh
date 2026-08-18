import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_token_gateway.g.dart';

/// What the HTTP layer needs from authentication — and nothing more.
///
/// The interceptor below `core/network/` must attach a token, renew it, and give up.
/// It must not know about Google, Firebase, secure storage, or routing. Declaring that
/// need as an interface here keeps `core/` from importing a feature: the auth feature
/// implements this, and the dependency points the right way.
abstract interface class AuthTokenGateway {
    /// The stored session JWT, or `null` when signed out. Called before every request.
    Future<String?> currentToken();

    /// Silent re-authentication (ADR 0007): mint a fresh Google ID token, exchange it
    /// for a new session JWT, store it, and return it.
    ///
    /// Returns `null` for the terminal case — Google access revoked, account removed,
    /// refresh token invalidated. The interceptor then stops trying; it does not decide
    /// what happens next.
    Future<String?> renewToken();

    /// Sign-in cannot be repaired. Drop stored session state and take the user to the
    /// sign-in screen. Must be idempotent: concurrent failures can call it twice.
    Future<void> abandonSession();
}

/// The seam between `core/` and the auth feature.
///
/// Defaults to `null`, which produces an unauthenticated Dio — correct for `GET /health`
/// and for any test that has no interest in sign-in. `main.dart` overrides it with the
/// real `AuthService`; a default that threw instead would make every widget test declare
/// an auth stub it does not use.
@Riverpod(keepAlive: true)
AuthTokenGateway? authTokenGateway(AuthTokenGatewayRef ref) => null;
