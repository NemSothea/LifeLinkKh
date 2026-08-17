package kh.lifelink.api.donor;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import kh.lifelink.api.donor.dto.EligibilityResponse;
import org.junit.jupiter.api.Test;

/**
 * The 56-day rule. A fixed "today" rather than the real one — a boundary test that depends on the
 * day it runs is not a test.
 */
class EligibilityCalculatorTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 8, 17);

    @Test
    void neverHavingDonatedMeansEligible() {
        EligibilityResponse result = EligibilityCalculator.forLastDonation(null, TODAY);

        assertThat(result.isEligible()).isTrue();
        assertThat(result.daysRemaining()).isNull();
        assertThat(result.eligibleOn()).isNull();
    }

    /** Exactly 56 days is eligible. The comparison is {@code <=}, and this is the whole rule. */
    @Test
    void exactlyFiftySixDaysAgoIsEligible() {
        LocalDate lastDonation = TODAY.minusDays(56);

        assertThat(EligibilityCalculator.forLastDonation(lastDonation, TODAY).isEligible())
                .isTrue();
    }

    /** The off-by-one on the other side of the same boundary. */
    @Test
    void fiftyFiveDaysAgoIsOneDayShort() {
        LocalDate lastDonation = TODAY.minusDays(55);

        EligibilityResponse result = EligibilityCalculator.forLastDonation(lastDonation, TODAY);

        assertThat(result.isEligible()).isFalse();
        assertThat(result.daysRemaining()).isEqualTo(1);
        assertThat(result.eligibleOn()).isEqualTo(LocalDate.of(2026, 8, 18));
    }

    /**
     * The prototype's amber state — "Eligible in 12 days (14 Aug 2026)". Both halves are asserted
     * because the donor writes down the date and acts on the count.
     */
    @Test
    void aRecentDonationReportsBothTheCountAndTheDate() {
        LocalDate lastDonation = TODAY.minusDays(44);

        EligibilityResponse result = EligibilityCalculator.forLastDonation(lastDonation, TODAY);

        assertThat(result.isEligible()).isFalse();
        assertThat(result.daysRemaining()).isEqualTo(12);
        assertThat(result.eligibleOn()).isEqualTo(lastDonation.plusDays(56));
    }

    @Test
    void aDonationLongAgoIsEligibleWithNoCountdown() {
        EligibilityResponse result =
                EligibilityCalculator.forLastDonation(TODAY.minusYears(2), TODAY);

        assertThat(result.isEligible()).isTrue();
        assertThat(result.daysRemaining()).isNull();
    }
}
