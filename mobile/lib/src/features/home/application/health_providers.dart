import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../data/dio_health_repository.dart';
import '../domain/health_repository.dart';
import '../domain/health_status.dart';
import 'health_service.dart';

part 'health_providers.g.dart';

/// The composition root for this feature — deliberately the only file that names a
/// concrete implementation. `application/` importing `data/` is an outward arrow and
/// the one the course sanctions, because it is what keeps every other layer free of
/// the concrete type.
@Riverpod(keepAlive: true)
HealthRepository healthRepository(HealthRepositoryRef ref) =>
    DioHealthRepository(ref.watch(apiClientProvider));

/// `ref.watch`, not `ref.read`: a test that overrides [healthRepositoryProvider] must
/// have that override reach the Service.
@Riverpod(keepAlive: true)
HealthService healthService(HealthServiceRef ref) =>
    HealthService(ref.watch(healthRepositoryProvider));

/// `keepAlive` on the two above because a repository and a service are singleton-like
/// and cheap to keep; this one is left autoDispose so the check re-runs on a fresh
/// visit rather than serving a stale answer.
///
/// Still a future-provider rather than an `AsyncNotifier`, which is Week 5's subject.
/// It lands with the M3 screens, where there is a retry and an empty state to build.
@riverpod
Future<HealthStatus> healthStatus(HealthStatusRef ref) =>
    ref.watch(healthServiceProvider).check();
