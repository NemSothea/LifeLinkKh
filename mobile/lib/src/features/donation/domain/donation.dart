/// One completed, hospital-confirmed donation — `GET /donations/me`.
///
/// The only write path to this data is a hospital's `confirm-donation` call
/// (`docs/fullstack/api-contract/web/contract.md`); nothing on this client ever creates
/// or edits a row here. A donor's own self-report is not a donation record.
final class Donation {
    const Donation({
        required this.id,
        required this.donatedOn,
        this.hospitalName,
        this.hospitalDistrictKm,
        this.hospitalDistrictEn,
        this.bloodRequestId,
    });

    final String id;
    final DateTime donatedOn;

    /// Null only if the hospital that confirmed this donation has since been removed —
    /// there is no code path that creates a donation with no hospital.
    final String? hospitalName;
    final String? hospitalDistrictKm;
    final String? hospitalDistrictEn;

    /// Null for a walk-in donation with no originating request (FR-08).
    final String? bloodRequestId;

    String? hospitalDistrictLabel(String languageCode) =>
        languageCode == 'en' ? hospitalDistrictEn : hospitalDistrictKm;
}
