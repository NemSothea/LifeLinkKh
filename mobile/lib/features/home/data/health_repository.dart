import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Reads `GET /health` — the one endpoint defined in
/// `docs/fullstack/api-contract/mobile/openapi.yaml` at M2. Proves the whole config
/// chain: dart-define → Dio → the backend container.
class HealthRepository {
    HealthRepository(this._dio);

    final Dio _dio;

    /// Returns the reported status, or throws. Callers use [AsyncValue] to render the
    /// error state — the exception detail never reaches the screen.
    Future<String> fetchStatus() async {
        final response = await _dio.get<Map<String, dynamic>>('/health');
        final status = response.data?['status'];
        if (status is! String) {
            throw const FormatException('health response has no status field');
        }
        return status;
    }
}

final healthRepositoryProvider = Provider<HealthRepository>(
    (ref) => HealthRepository(ref.watch(apiClientProvider)),
);

final healthStatusProvider = FutureProvider<String>(
    (ref) => ref.watch(healthRepositoryProvider).fetchStatus(),
);
