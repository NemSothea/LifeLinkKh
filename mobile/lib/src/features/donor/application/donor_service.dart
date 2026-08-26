import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/district.dart';
import '../domain/donor_profile.dart';
import '../domain/donor_profile_draft.dart';
import '../domain/donor_repository.dart';

/// The DONOR feature's Service (S1–S6). No Flutter import, no Riverpod import.
///
/// Unlike `HealthService` this one has something to orchestrate: it refuses an incomplete
/// draft before spending a round trip, and it turns a saved profile back into a draft so the
/// edit screen has something to open with.
final class DonorService {
    const DonorService(this._repository);

    final DonorRepository _repository;

    /// `Success(null)` means no profile yet — the state every donor starts in.
    Future<Result<DonorProfile?>> loadProfile() => _repository.fetchProfile();

    Future<Result<List<District>>> loadDistricts() => _repository.fetchDistricts();

    /// Saves, refusing locally only what the client can be sure about.
    ///
    /// The three required fields are checked here so the last step of setup does not need a
    /// round trip to say "pick a blood type". Everything else — future dates, unknown
    /// districts — goes to the server, which is the side that can actually know.
    Future<Result<DonorProfile>> save(DonorProfileDraft draft) async {
        if (!draft.isComplete) {
            return const Failed(
                ValidationFailure(code: 'INCOMPLETE_DRAFT', message: 'draft is missing a required field'),
            );
        }
        return _repository.saveProfile(draft);
    }

    /// Seeds the edit form from a saved profile.
    ///
    /// Coordinates are always absent here — the read model never carries them (ADR 0003) — and
    /// that is fine now: the resulting draft's `updateCoordinates` defaults to `false`, and
    /// CR-MAPI-004 made the server treat that as "leave stored coordinates alone" rather than
    /// "clear them". A donor who edits their name without tapping "use my current location"
    /// again keeps whatever precision they already had.
    DonorProfileDraft draftFrom(DonorProfile profile) => DonorProfileDraft(
        fullName: profile.fullName,
        bloodType: profile.bloodType,
        districtCode: profile.districtCode,
        lastDonationDate: profile.lastDonationDate,
        isAvailable: profile.isAvailable,
    );
}
