import 'blood_type.dart';

/// What the three setup steps accumulate, and what `PUT /donors/me` sends.
///
/// A separate type from `DonorProfile` for two reasons that are both about what each one
/// holds: this one is incomplete while the user is filling it in, and this one carries
/// **coordinates**, which the read model must never have.
///
/// [isComplete] is the only validity rule the client enforces, and it mirrors
/// `FR-DONOR-001`: a name, a blood type and a district are required; a date and coordinates
/// are not. Everything else — the future-date rule, whether the district exists — is the
/// server's, because it is the side that can actually know.
final class DonorProfileDraft {
    const DonorProfileDraft({
        this.fullName = '',
        this.bloodType,
        this.districtCode,
        this.latitude,
        this.longitude,
        this.updateCoordinates = false,
        this.lastDonationDate,
        this.isAvailable = true,
    });

    final String fullName;
    final BloodType? bloodType;
    final String? districtCode;

    /// Optional, and sent only as a pair — the server answers 400
    /// `INCOMPLETE_COORDINATES` for one without the other. Declining the GPS permission must
    /// still produce a matchable profile (ADR 0003), so null here is a normal outcome.
    final double? latitude;
    final double? longitude;

    /// CR-MAPI-004. `false` unless [setCoordinates] (or an explicit clear) ran this session —
    /// no response ever hands coordinates back, so a draft that never touched location must
    /// leave whatever is already stored alone rather than wiping it on the next save.
    final bool updateCoordinates;

    /// Null means never donated. A first-time donor finishes setup without touching a date.
    final DateTime? lastDonationDate;

    final bool isAvailable;

    bool get isComplete =>
        fullName.trim().isNotEmpty && bloodType != null && districtCode != null;

    DonorProfileDraft copyWith({
        String? fullName,
        BloodType? bloodType,
        String? districtCode,
        double? latitude,
        double? longitude,
        DateTime? lastDonationDate,
        bool? isAvailable,
        bool clearLastDonationDate = false,
        bool clearCoordinates = false,
    }) {
        // Sticky once true: a donor who acquires a fix and then edits their name must not
        // have that fix silently downgraded back to "leave coordinates alone" on save.
        final touchesCoordinates = clearCoordinates || latitude != null || longitude != null;
        return DonorProfileDraft(
            fullName: fullName ?? this.fullName,
            bloodType: bloodType ?? this.bloodType,
            districtCode: districtCode ?? this.districtCode,
            // Explicit clear flags, because `copyWith(latitude: null)` cannot mean "remove" in
            // Dart — a null argument is indistinguishable from an absent one. "I have never
            // donated" needs to mean *remove the date*, not *leave it alone*.
            latitude: clearCoordinates ? null : latitude ?? this.latitude,
            longitude: clearCoordinates ? null : longitude ?? this.longitude,
            updateCoordinates: touchesCoordinates || updateCoordinates,
            lastDonationDate:
                clearLastDonationDate ? null : lastDonationDate ?? this.lastDonationDate,
            isAvailable: isAvailable ?? this.isAvailable,
        );
    }

    @override
    String toString() =>
        'DonorProfileDraft($fullName, ${bloodType?.wireValue}, $districtCode, '
        'coords: ${latitude != null}, date: $lastDonationDate)';
}
