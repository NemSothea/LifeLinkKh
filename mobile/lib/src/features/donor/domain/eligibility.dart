/// The 56-day cooldown, as the server computed it.
///
/// Computed there and read here, never recalculated: two implementations of one rule will
/// disagree, and the one on the device is the one that cannot be fixed without a release.
final class Eligibility {
    const Eligibility({
        required this.isEligible,
        this.daysRemaining,
        this.eligibleOn,
    });

    final bool isEligible;

    /// Null when already eligible.
    final int? daysRemaining;

    /// Null when already eligible. `FR-DONOR-001` requires the result screen to show this
    /// *and* [daysRemaining] — "Eligible in 12 days (14 Aug 2026)" — because a countdown alone
    /// is unusable for planning and a date alone hides how close it is.
    final DateTime? eligibleOn;

    @override
    bool operator ==(Object other) =>
        other is Eligibility &&
        other.isEligible == isEligible &&
        other.daysRemaining == daysRemaining &&
        other.eligibleOn == eligibleOn;

    @override
    int get hashCode => Object.hash(isEligible, daysRemaining, eligibleOn);

    @override
    String toString() =>
        'Eligibility(eligible: $isEligible, in: $daysRemaining days, on: $eligibleOn)';
}
