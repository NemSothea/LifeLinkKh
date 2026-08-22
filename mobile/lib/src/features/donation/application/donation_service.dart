import '../../../core/error/result.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';

/// The DONATION feature's service. No Flutter import, no Riverpod import.
final class DonationService {
    const DonationService(this._repository);

    final DonationRepository _repository;

    Future<Result<List<Donation>>> loadMine() => _repository.fetchMine();
}
