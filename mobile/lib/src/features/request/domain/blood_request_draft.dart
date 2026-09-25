import '../../../core/phone/cambodian_phone.dart';
import '../../donor/domain/blood_type.dart';
import 'urgency.dart';

/// What the request form accumulates, and what `POST /requests` sends.
///
/// [isComplete] mirrors `RequestCreateRequest`'s `@NotBlank`/`@NotNull` fields —
/// everything the server requires. There is no separate "form validity" concept
/// beyond it because a one-minute form has no field the server would accept
/// missing.
final class RequestDraft {
    const RequestDraft({
        this.patientBloodType,
        this.unitsNeeded = 1,
        this.hospitalId,
        this.urgency = Urgency.defaultValue,
        this.contactName = '',
        this.contactPhone = '',
    });

    final BloodType? patientBloodType;
    final int unitsNeeded;
    final String? hospitalId;
    final Urgency urgency;

    /// Who the donor asks for on arrival (CR-MAPI-003).
    final String contactName;

    /// Revealed to a donor only after they accept. Raw, as typed — see [normalizedContactPhone].
    final String contactPhone;

    /// [contactPhone] as `+855XXXXXXXX`, or null if it is not a Cambodian mobile number.
    String? get normalizedContactPhone => CambodianPhone.normalize(contactPhone);

    bool get isComplete =>
        patientBloodType != null &&
        unitsNeeded >= 1 &&
        hospitalId != null &&
        contactName.trim().isNotEmpty &&
        normalizedContactPhone != null;

    RequestDraft copyWith({
        BloodType? patientBloodType,
        int? unitsNeeded,
        String? hospitalId,
        Urgency? urgency,
        String? contactName,
        String? contactPhone,
    }) {
        return RequestDraft(
            patientBloodType: patientBloodType ?? this.patientBloodType,
            unitsNeeded: unitsNeeded ?? this.unitsNeeded,
            hospitalId: hospitalId ?? this.hospitalId,
            urgency: urgency ?? this.urgency,
            contactName: contactName ?? this.contactName,
            contactPhone: contactPhone ?? this.contactPhone,
        );
    }
}
