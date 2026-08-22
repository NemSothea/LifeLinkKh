import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../donor/domain/blood_type.dart';
import '../domain/blood_request_draft.dart';
import '../domain/urgency.dart';

part 'request_form_controller.g.dart';

/// Drives the one-screen request form. `autoDispose` (the default): leaving the
/// form discards it, same as `DonorSetup` — a half-filled urgent request is not
/// something to resurface later.
@riverpod
class RequestFormController extends _$RequestFormController {
    @override
    RequestDraft build() => const RequestDraft();

    void setBloodType(BloodType type) => state = state.copyWith(patientBloodType: type);

    void setUnits(int units) {
        if (units < 1) return;
        state = state.copyWith(unitsNeeded: units);
    }

    void setHospital(String hospitalId) => state = state.copyWith(hospitalId: hospitalId);

    void setUrgency(Urgency urgency) => state = state.copyWith(urgency: urgency);

    void setContactName(String value) => state = state.copyWith(contactName: value);

    void setContactPhone(String value) => state = state.copyWith(contactPhone: value);
}
