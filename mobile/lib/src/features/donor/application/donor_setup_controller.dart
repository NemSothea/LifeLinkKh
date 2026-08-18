// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/blood_type.dart';
import '../domain/donor_profile_draft.dart';

part 'donor_setup_controller.g.dart';

/// Where the three-step flow currently is, and what it has collected.
///
/// A provider rather than widget state because Week 4 bans `setState` for anything a
/// provider can hold — and because the steps are separate widgets that would otherwise have
/// to pass the draft down and callbacks back up.
final class DonorSetupState {
    const DonorSetupState({required this.draft, this.step = 0});

    final DonorProfileDraft draft;

    /// 0 identity · 1 location · 2 last donation. Three, per `FR-DONOR-001`.
    final int step;

    static const int stepCount = 3;

    bool get isFirstStep => step == 0;
    bool get isLastStep => step == stepCount - 1;

    /// Whether the current step may be left. Per-step rather than one `isComplete`, so a
    /// donor is stopped on the step that is missing something instead of at the end.
    bool get canAdvance => switch (step) {
        0 => draft.fullName.trim().isNotEmpty && draft.bloodType != null,
        1 => draft.districtCode != null,
        // The date is optional. "I have never donated" and "I did not answer" are the same
        // stored value, and both are valid.
        _ => true,
    };

    DonorSetupState copyWith({DonorProfileDraft? draft, int? step}) =>
        DonorSetupState(draft: draft ?? this.draft, step: step ?? this.step);
}

/// Drives the setup wizard. `autoDispose` (the default) on purpose: leaving the flow discards
/// a half-filled draft rather than showing it again days later.
@riverpod
class DonorSetup extends _$DonorSetup {
    @override
    DonorSetupState build() => const DonorSetupState(draft: DonorProfileDraft());

    /// Opens the flow on an existing profile, for editing. Called once, from the screen.
    void seed(DonorProfileDraft draft) =>
        state = DonorSetupState(draft: draft);

    void setFullName(String value) =>
        state = state.copyWith(draft: state.draft.copyWith(fullName: value));

    void setBloodType(BloodType type) =>
        state = state.copyWith(draft: state.draft.copyWith(bloodType: type));

    void setDistrict(String code) =>
        state = state.copyWith(draft: state.draft.copyWith(districtCode: code));

    void setLastDonationDate(DateTime date) =>
        state = state.copyWith(draft: state.draft.copyWith(lastDonationDate: date));

    /// "I have never donated" — an explicit clear, not an unset field.
    void clearLastDonationDate() => state = state.copyWith(
        draft: state.draft.copyWith(clearLastDonationDate: true),
    );

    void next() {
        if (!state.canAdvance || state.isLastStep) return;
        state = state.copyWith(step: state.step + 1);
    }

    void back() {
        if (state.isFirstStep) return;
        state = state.copyWith(step: state.step - 1);
    }
}
