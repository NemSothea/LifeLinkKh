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
    /// **Coordinates are absent, and that is a problem waiting at M6.** The read model does not
    /// carry them (ADR 0003), so a draft built from a profile has none, and a `PUT` that sends
    /// null coordinates *clears* the stored ones — meaning a donor who edits their name would
    /// silently lose the precision that sorts them ahead of district-only donors.
    ///
    /// Latent today: nothing acquires coordinates until `geolocator` lands at M6 (root
    /// `CLAUDE.md` §4), so every profile has null coordinates already. It must be decided before
    /// then, and it is not the client's to decide alone — the candidates are a `PUT` that treats
    /// omitted coordinates as unchanged, a `PATCH`, or an edit screen that always re-acquires
    /// GPS. Raised as a CR-MAPI when M6 starts rather than guessed here.
    DonorProfileDraft draftFrom(DonorProfile profile) => DonorProfileDraft(
        fullName: profile.fullName,
        bloodType: profile.bloodType,
        districtCode: profile.districtCode,
        lastDonationDate: profile.lastDonationDate,
        isAvailable: profile.isAvailable,
    );
}
