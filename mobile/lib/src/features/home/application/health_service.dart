import '../domain/health_repository.dart';
import '../domain/health_status.dart';

/// The feature's Service, against the six rules from Week 3:
///
/// * **S1** one per feature — `HealthService`, not an `AppService`.
/// * **S2** stateless — no instance field holds UI state.
/// * **S3** returns domain types — `HealthStatus`, never a Dio `Response`.
/// * **S4** depends on the abstraction — the constructor takes [HealthRepository],
///   never `DioHealthRepository`.
/// * **S5** no Flutter import, and no Riverpod import either. Only the provider
///   function in `application/` imports `riverpod_annotation`.
/// * **S6** orchestrates, never renders.
///
/// It is a pass-through today because one health check has nothing to orchestrate.
/// That is the point of the seam, not an argument against it: `AuthService` at M3 has
/// a token exchange and a profile lookup to sequence, and it will sit exactly here.
final class HealthService {
    const HealthService(this._repository);

    final HealthRepository _repository;

    Future<HealthStatus> check() => _repository.fetchStatus();
}
