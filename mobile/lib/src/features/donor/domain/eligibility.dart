/// The 56-day cooldown.
///
/// Until ADR 0009 the server computed this and the app only read it, on the principle that
/// two implementations of one rule will disagree. With no server there are now two anyway —
/// [Eligibility.forLastDonation] for what the donor sees, and the matching Function for who
/// gets alerted. Both are ports of `EligibilityCalculator.forLastDonation`, and both have a
/// test pinning the 56-day boundary, which is the only place they could drift.
final class Eligibility {
    const Eligibility({
        required this.isEligible,
        this.daysRemaining,
        this.eligibleOn,
    });

    /// Days between donations. `EligibilityCalculator.COOLDOWN_DAYS` on the old backend.
    static const int cooldownDays = 56;

    /// Eligibility on [today] for a donor who last gave on [lastDonationDate].
    ///
    /// Both are calendar dates: only year, month and day are read, so the time of day and
    /// the device timezone cannot move the boundary. Exactly 56 days after donating is
    /// eligible — `<=`, not `<`, same as the backend.
    factory Eligibility.forLastDonation(DateTime? lastDonationDate, DateTime today) {
        // Null is a first-time donor, and a first-time donor is eligible.
        if (lastDonationDate == null) return const Eligibility(isEligible: true);
        final last = DateTime.utc(lastDonationDate.year, lastDonationDate.month, lastDonationDate.day);
        final now = DateTime.utc(today.year, today.month, today.day);
        final eligibleOnUtc = last.add(const Duration(days: cooldownDays));
        if (!eligibleOnUtc.isAfter(now)) return const Eligibility(isEligible: true);
        return Eligibility(
            isEligible: false,
            daysRemaining: eligibleOnUtc.difference(now).inDays,
            eligibleOn: DateTime(eligibleOnUtc.year, eligibleOnUtc.month, eligibleOnUtc.day),
        );
    }

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
