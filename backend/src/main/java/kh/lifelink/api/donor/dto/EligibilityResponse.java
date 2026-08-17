package kh.lifelink.api.donor.dto;

import java.time.LocalDate;

/**
 * The 56-day cooldown, computed server-side on every read. The client never calculates it — the
 * prototype's result screen shows both a countdown and an absolute date, and both come from here.
 *
 * @param isEligible whether this donor may donate today
 * @param daysRemaining null when already eligible
 * @param eligibleOn null when already eligible
 */
public record EligibilityResponse(boolean isEligible, Integer daysRemaining, LocalDate eligibleOn) {

    public static EligibilityResponse eligible() {
        return new EligibilityResponse(true, null, null);
    }

    public static EligibilityResponse notUntil(LocalDate eligibleOn, int daysRemaining) {
        return new EligibilityResponse(false, daysRemaining, eligibleOn);
    }
}
