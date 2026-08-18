// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:dio/dio.dart';

import 'auth_token_gateway.dart';

/// Attaches the session JWT, and repairs a 401 exactly once (ADR 0007).
///
/// This is the easiest-to-get-wrong code in the mobile app, so each rule below is one
/// of the ADR's, stated as the failure it prevents:
///
/// * **One retry, never a loop.** A second 401 after a successful renewal is a real
///   failure. Retrying again is how a client hammers an endpoint that will never say
///   yes.
/// * **`POST /auth/google` is never retried.** A 401 there means the Google credential
///   itself is gone. Retrying it re-runs the thing that just failed; the correct move is
///   to abandon the session.
/// * **Concurrent 401s collapse into one renewal.** A cold start firing three requests
///   must send one sign-in, not three. This is the case that only appears on a real
///   network, and it is the one QA treats as non-negotiable.
/// * **`exp` is never inspected.** A 401 is the only trigger. Reading expiry here means
///   trusting the device clock and running a second rule that can disagree with the
///   server's.
final class AuthInterceptor extends Interceptor {
    AuthInterceptor({
        required AuthTokenGateway gateway,
        required Dio Function() client,
        this.signInPath = '/auth/google',
    })  : _gateway = gateway,
          _client = client;

    final AuthTokenGateway _gateway;

    /// Resolved lazily because the Dio instance this interceptor is installed on is the
    /// same one used to replay the failed request — the two cannot be constructed in
    /// dependency order otherwise.
    final Dio Function() _client;

    /// The one unauthenticated path that may return 401 as a real answer.
    final String signInPath;

    /// Marks a request that has already been replayed once.
    static const String _retriedKey = 'lifelink.auth.retried';

    /// The in-flight renewal, shared by every request that 401s while it runs.
    Future<String?>? _renewal;

    @override
    Future<void> onRequest(
        RequestOptions options,
        RequestInterceptorHandler handler,
    ) async {
        if (_isSignIn(options)) {
            // Sending a stale bearer token to the endpoint that mints one is at best
            // noise and at worst a 401 on the path that cannot be repaired.
            return handler.next(options);
        }
        final token = await _gateway.currentToken();
        if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
    }

    @override
    Future<void> onError(
        DioException err,
        ErrorInterceptorHandler handler,
    ) async {
        if (err.response?.statusCode != 401) return handler.next(err);

        final options = err.requestOptions;

        if (_isSignIn(options)) {
            // Terminal: the Google credential is gone. Not repairable by definition.
            await _gateway.abandonSession();
            return handler.next(err);
        }

        if (options.extra[_retriedKey] == true) {
            // Renewed once and still refused. The ADR is explicit that this is a real
            // failure to surface, *not* a stale token — so it is not treated as a lost
            // session either. Signing the user out here would turn one endpoint's
            // authorization bug into a forced re-login.
            return handler.next(err);
        }

        final token = await _renewOnce();
        if (token == null) {
            await _gateway.abandonSession();
            return handler.next(err);
        }

        options.extra[_retriedKey] = true;
        options.headers['Authorization'] = 'Bearer $token';
        try {
            // `fetch` deliberately bypasses the interceptor chain: going back through
            // `onRequest` would re-read the token and, on another 401, re-enter this
            // method with the flag it just set — correct, but one layer of recursion for
            // nothing.
            handler.resolve(await _client().fetch<dynamic>(options));
        } on DioException catch (retryError) {
            handler.next(retryError);
        }
    }

    /// Single-flight renewal. The second and third callers await the first one's future
    /// instead of starting their own.
    Future<String?> _renewOnce() {
        final inFlight = _renewal;
        if (inFlight != null) return inFlight;

        // Assigned before the first await inside `renewToken` can yield, which is what
        // makes this safe without a lock: Dart interleaves only at await points.
        final renewal = _gateway.renewToken();
        _renewal = renewal;
        return renewal.whenComplete(() => _renewal = null);
    }

    bool _isSignIn(RequestOptions options) => options.path.endsWith(signInPath);
}
