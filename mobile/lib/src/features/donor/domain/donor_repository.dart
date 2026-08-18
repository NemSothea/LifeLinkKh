import '../../../core/error/result.dart';
import 'district.dart';
import 'donor_profile.dart';
import 'donor_profile_draft.dart';

/// `GET`/`PUT /donors/me` and `GET /districts`, as the rest of the app sees them.
abstract interface class DonorRepository {
    /// The caller's own profile.
    ///
    /// `Success(null)` for a 404 — that is the normal state of a donor mid-signup and of every
    /// REQUESTER, so it is an answer, not a `NotFoundFailure`. Making it a failure would put
    /// an error screen in front of every first-time donor.
    Future<Result<DonorProfile?>> fetchProfile();

    /// Create or update. There is no POST: the row is keyed on the JWT subject and the client
    /// does not know or care which case this is.
    Future<Result<DonorProfile>> saveProfile(DonorProfileDraft draft);

    /// The district dropdown's options, already sorted by Khmer name server-side.
    ///
    /// Fetched rather than bundled: `districtCode` is a foreign key, so a stale local list
    /// produces a 422 the donor cannot act on — "that district is not valid" for the district
    /// they live in.
    Future<Result<List<District>>> fetchDistricts();
}
