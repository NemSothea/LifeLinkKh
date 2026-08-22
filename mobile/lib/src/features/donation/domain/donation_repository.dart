import '../../../core/error/result.dart';
import 'donation.dart';

/// `GET /donations/me`, as the rest of the app sees it. Read-only — see [Donation].
abstract interface class DonationRepository {
    /// Newest first, matching the server's own order. Empty for a donor who has never
    /// had a donation confirmed — the normal state for every donor at first, not a
    /// failure.
    Future<Result<List<Donation>>> fetchMine();
}
