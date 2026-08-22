import '../../donor/domain/blood_type.dart';
import 'request_status.dart';
import 'requester_contact.dart';
import 'urgency.dart';

/// A blood request, as its creator or a matched donor sees it.
///
/// One type for both `BloodRequestResponse` (list) and `BloodRequestDetailResponse`
/// (detail) on the server, rather than two nearly-identical client types: the only
/// difference is that [distanceKm] and [requesterContact] are always null on the
/// list shape. A screen that only ever receives the list shape simply never reads
/// those two fields.
final class BloodRequest {
    const BloodRequest({
        required this.id,
        required this.status,
        required this.patientBloodType,
        required this.unitsNeeded,
        required this.urgency,
        required this.hospitalName,
        required this.alertedCount,
        required this.acceptedCount,
        required this.createdAt,
        this.hospitalDistrictKm,
        this.hospitalDistrictEn,
        this.distanceKm,
        this.requesterContact,
    });

    final String id;
    final RequestStatus status;
    final BloodType patientBloodType;
    final int unitsNeeded;
    final Urgency urgency;
    final String hospitalName;
    final String? hospitalDistrictKm;
    final String? hospitalDistrictEn;

    /// `request_matches` rows written, not pushes delivered (`prd.md`'s ≥95%
    /// delivery metric is measured separately, over `notified_at`).
    final int alertedCount;

    /// Computed on read by the server, never a counter column here either.
    final int acceptedCount;

    final DateTime createdAt;

    /// Rounded to 0.5 km server-side. Null on the list shape and for the request's
    /// own creator; present only when the caller is a matched donor with coordinates.
    final double? distanceKm;

    /// Null unless the caller is a donor whose own match is ACCEPTED.
    final RequesterContact? requesterContact;

    String? hospitalDistrictLabel(String languageCode) =>
        languageCode == 'en' ? hospitalDistrictEn : hospitalDistrictKm;

    /// Used only after `POST /matches/{id}/respond` accepts — folds the newly
    /// revealed contact into the request already held in the donor's inbox, rather
    /// than re-fetching a detail this donor already has every field of.
    BloodRequest withRequesterContact(RequesterContact contact) => BloodRequest(
        id: id,
        status: status,
        patientBloodType: patientBloodType,
        unitsNeeded: unitsNeeded,
        urgency: urgency,
        hospitalName: hospitalName,
        hospitalDistrictKm: hospitalDistrictKm,
        hospitalDistrictEn: hospitalDistrictEn,
        alertedCount: alertedCount,
        acceptedCount: acceptedCount,
        createdAt: createdAt,
        distanceKm: distanceKm,
        requesterContact: contact,
    );
}
