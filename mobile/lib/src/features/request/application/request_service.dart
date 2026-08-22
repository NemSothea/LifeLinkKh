import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/blood_request.dart';
import '../domain/blood_request_draft.dart';
import '../domain/hospital.dart';
import '../domain/request_repository.dart';

/// The REQUEST feature's service. No Flutter import, no Riverpod import — same
/// split as `DonorService`.
final class RequestService {
    const RequestService(this._repository);

    final RequestRepository _repository;

    Future<Result<List<Hospital>>> loadHospitals() => _repository.fetchHospitals();

    /// Refuses locally only what the client can already be sure about, same
    /// reasoning as `DonorService.save` — everything else (an unknown hospital id,
    /// an unrecognised urgency) is the server's call.
    Future<Result<BloodRequest>> create(RequestDraft draft) async {
        if (!draft.isComplete) {
            return const Failed(
                ValidationFailure(
                    code: 'INCOMPLETE_DRAFT',
                    message: 'draft is missing a required field',
                ),
            );
        }
        return _repository.create(draft);
    }

    Future<Result<List<BloodRequest>>> loadMine() => _repository.fetchMine();

    Future<Result<BloodRequest>> loadDetail(String requestId) =>
        _repository.fetchDetail(requestId);

    Future<Result<BloodRequest>> cancel(String requestId) => _repository.cancel(requestId);
}
