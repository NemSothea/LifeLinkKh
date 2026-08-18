import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';
import 'auth_token_gateway.dart';

part 'api_client.g.dart';

BaseOptions _baseOptions() => BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    // The urgent-request path cannot hang: a family waiting on a blood
    // request needs an error they can act on, not a spinner.
    headers: const {'Content-Type': 'application/json'},
);

/// The Dio every authenticated call goes through.
///
/// Pass [authGateway] to install the ADR 0007 interceptor. Omitting it yields a plain
/// client — which is what `GET /health` needs and what a unit test wants.
Dio createApiClient({AuthTokenGateway? authGateway}) {
    final dio = Dio(_baseOptions());
    if (authGateway != null) {
        dio.interceptors.add(
            // `() => dio` rather than `dio`: the interceptor replays the failed request on
            // the same client it is installed in, so one of the two references has to be
            // deferred.
            AuthInterceptor(gateway: authGateway, client: () => dio),
        );
    }
    return dio;
}

/// A client with **no** auth interceptor, for `POST /auth/google` alone.
///
/// Separate instance, not a flag: renewing a session over a client that attaches and
/// repairs sessions is the recursion ADR 0007 warns about. Keeping sign-in on its own
/// transport makes that structurally impossible rather than merely avoided.
Dio createSignInApiClient() => Dio(_baseOptions());

@Riverpod(keepAlive: true)
Dio apiClient(ApiClientRef ref) =>
    createApiClient(authGateway: ref.watch(authTokenGatewayProvider));

@Riverpod(keepAlive: true)
Dio signInApiClient(SignInApiClientRef ref) => createSignInApiClient();
