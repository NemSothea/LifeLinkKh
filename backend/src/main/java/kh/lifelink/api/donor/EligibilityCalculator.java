package kh.lifelink.api.donor;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import kh.lifelink.api.donor.dto.EligibilityResponse;

/**
 * The one real business rule in the product: 56 days between donations.
 *
 * <p>Computed on read, never stored. A cached copy is a value that goes stale at midnight with
 * nothing to wake it up.
 *
 * <p><strong>Milestone note.</strong> {@code CLAUDE.md} §4 places eligibility computation in M4,
 * but the mobile contract requires an {@code eligibility} object on {@code GET /donors/me} at M3
 * and FR-DONOR-001's save-result screen displays it. Those cannot both hold; openapi wins on
 * conflict (docs/fullstack/CLAUDE.md), so it is here. The milestone tables still disagree and that
 * is flagged for Tech Lead and PO in the spec — not resolved by this class.
 */
final class EligibilityCalculator {

    static final int COOLDOWN_DAYS = 56;

    private EligibilityCalculator() {}

    static EligibilityResponse forLastDonation(LocalDate lastDonationDate, LocalDate today) {
        // NULL means never donated — the correct state for a first-time donor, and eligible.
        if (lastDonationDate == null) {
            return EligibilityResponse.eligible();
        }

        LocalDate eligibleOn = lastDonationDate.plusDays(COOLDOWN_DAYS);
        if (!eligibleOn.isAfter(today)) {
            return EligibilityResponse.eligible();
        }

        // Exactly 56 days after donating, a donor is eligible — the boundary above is <=, not <.
        int daysRemaining = (int) ChronoUnit.DAYS.between(today, eligibleOn);
        return EligibilityResponse.notUntil(eligibleOn, daysRemaining);
    }
}
