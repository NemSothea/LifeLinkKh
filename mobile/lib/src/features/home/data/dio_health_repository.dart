import 'package:dio/dio.dart';

import '../domain/health_repository.dart';
import '../domain/health_status.dart';

/// Reads `GET /health` — the one endpoint defined in
/// `docs/fullstack/api-contract/mobile/openapi.yaml` at M2. Proves the whole config
/// chain: dart-define → Dio → the backend container.
///
/// The only class in this feature that knows Dio exists. Named for its transport, not
/// for the thing it implements, so a second implementation reads as an alternative
/// rather than as a replacement.
final class DioHealthRepository implements HealthRepository {
    DioHealthRepository(this._dio);

    final Dio _dio;

    @override
    Future<HealthStatus> fetchStatus() async {
        final response = await _dio.get<Map<String, dynamic>>('/health');
        final status = response.data?['status'];
        if (status is! String) {
            throw const FormatException('health response has no status field');
        }
        return HealthStatus(status);
    }
}
