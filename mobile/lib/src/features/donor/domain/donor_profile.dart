import 'blood_type.dart';
import 'eligibility.dart';

/// The donor profile as `GET`/`PUT /donors/me` return it.
///
/// **No latitude or longitude.** They are absent, not null — the server does not send them
/// even to the donor who owns them (ADR 0003). The client keeps the same shape so that a
/// future screen cannot read a coordinate off a profile object and put it on a wire.
final class DonorProfile {
    const DonorProfile({
        required this.id,
        required this.fullName,
        required this.bloodType,
        required this.districtCode,
        required this.districtNameKm,
        required this.districtNameEn,
        required this.isAvailable,
        required this.eligibility,
        this.lastDonationDate,
    });

    final String id;
    final String fullName;
    final BloodType bloodType;

    final String districtCode;
    final String districtNameKm;
    final String districtNameEn;

    /// Null means never donated — which is a complete profile, not a missing field.
    final DateTime? lastDonationDate;

    /// False hides the donor from matching without deleting anything.
    final bool isAvailable;

    final Eligibility eligibility;

    String districtLabel(String languageCode) =>
        languageCode == 'en' ? districtNameEn : districtNameKm;

    @override
    bool operator ==(Object other) =>
        other is DonorProfile &&
        other.id == id &&
        other.fullName == fullName &&
        other.bloodType == bloodType &&
        other.districtCode == districtCode &&
        other.districtNameKm == districtNameKm &&
        other.districtNameEn == districtNameEn &&
        other.lastDonationDate == lastDonationDate &&
        other.isAvailable == isAvailable &&
        other.eligibility == eligibility;

    @override
    int get hashCode => Object.hash(
        id,
        fullName,
        bloodType,
        districtCode,
        districtNameKm,
        districtNameEn,
        lastDonationDate,
        isAvailable,
        eligibility,
    );

    @override
    String toString() => 'DonorProfile($id, ${bloodType.wireValue}, $districtCode)';
}
