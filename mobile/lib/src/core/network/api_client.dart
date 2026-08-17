import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';

part 'api_client.g.dart';

/// The single Dio instance. Interceptors for the JWT bearer token arrive at M3 —
/// this exists now so that adding one is a change in one place.
Dio createApiClient() {
    return Dio(
        BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            // The urgent-request path cannot hang: a family waiting on a blood
            // request needs an error they can act on, not a spinner.
            headers: const {'Content-Type': 'application/json'},
        ),
    );
}

@Riverpod(keepAlive: true)
Dio apiClient(ApiClientRef ref) => createApiClient();
