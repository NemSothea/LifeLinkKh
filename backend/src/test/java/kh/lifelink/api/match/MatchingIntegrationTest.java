package kh.lifelink.api.match;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.donor.EligibilityCalculator;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * FR-MATCH-001 against a real PostgreSQL. The matching rule lives in SQL, so a mock proves nothing
 * about it — the compatibility join, {@code NULLS LAST}, the haversine and the {@code LIMIT} are
 * all database behaviour.
 *
 * <p>{@code disabledWithoutDocker = true}: this class SKIPS when no container runtime is present,
 * and a skip is not a pass (docs/qa/test-strategy.md).
 */
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest
@ActiveProfiles("test")
class MatchingIntegrationTest {

    @Container @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    /**
     * Somewhere central in Phnom Penh. The exact point does not matter; the distances from it do.
     */
    private static final BigDecimal HOSPITAL_LAT = new BigDecimal("11.58000");

    private static final BigDecimal HOSPITAL_LNG = new BigDecimal("104.92000");

    /** 1 degree of latitude is about 111 km, so this is roughly 1 km due north per unit. */
    private static final double KM_IN_DEGREES = 1.0 / 111.0;

    @Autowired private JdbcTemplate jdbc;
    @Autowired private MatchingService matching;
    @Autowired private HospitalRepository hospitals;

    private Hospital hospital;

    @BeforeEach
    void reset() {
        jdbc.update("DELETE FROM request_matches");
        jdbc.update("DELETE FROM blood_requests");
        jdbc.update("DELETE FROM donor_profiles");
        // users before hospitals: V8 added users.hospital_id, so a seeded HOSPITAL row now
        // references a hospital and must go first.
        jdbc.update("DELETE FROM users");
        jdbc.update("DELETE FROM hospitals");

        Hospital h = new Hospital();
        h.setName("Test Hospital");
        h.setLatitude(HOSPITAL_LAT);
        h.setLongitude(HOSPITAL_LNG);
        hospital = hospitals.save(h);
    }

    /**
     * The bug this exists to catch: swapping {@code recipient_type} and {@code donor_type} in the
     * join compiles, runs and returns rows. Compatibility is not symmetric, so it has to be checked
     * in the direction that would be wrong.
     */
    @Test
    void anONegativeDonorAnswersAnAPositivePatient() {
        UUID universal = donor("O-", 1);

        List<MatchingService.Candidate> matched = matching.findFor("A+", hospital);

        assertThat(matched)
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(universal);
    }

    @Test
    void anAPositiveDonorDoesNotAnswerAnONegativePatient() {
        donor("A+", 1);

        assertThat(matching.findFor("O-", hospital)).isEmpty();
    }

    @Test
    void anUnavailableDonorIsNeverMatched() {
        UUID available = donor("O-", 1);
        UUID unavailable = donor("O-", 2, false, null, true);

        assertThat(matching.findFor("A+", hospital))
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(available)
                .doesNotContain(unavailable);
    }

    /** The 56-day rule, at the boundary in both directions. Exactly 56 days is eligible. */
    @Test
    void theCooldownIsFiftySixDaysAndTheBoundaryIsEligible() {
        LocalDate today = LocalDate.now();
        UUID exactlyDue =
                donor("O-", 1, true, today.minusDays(EligibilityCalculator.COOLDOWN_DAYS), true);
        UUID oneDayShort =
                donor(
                        "O-",
                        2,
                        true,
                        today.minusDays(EligibilityCalculator.COOLDOWN_DAYS - 1),
                        true);

        assertThat(matching.findFor("A+", hospital))
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(exactlyDue)
                .doesNotContain(oneDayShort);
    }

    /** ADR 0008. Thirty qualify; twenty-five are alerted and the twenty-sixth is not. */
    @Test
    void atMostTwentyFiveDonorsAreMatched() {
        // All well inside the 10 km radius — this test is about the cap, not about the radius.
        for (int i = 1; i <= 30; i++) {
            donor("O-", 2);
        }

        assertThat(matching.findFor("A+", hospital)).hasSize(25);
    }

    /** The cap is a ceiling, never a target — nothing is padded to reach 25. */
    @Test
    void fewerThanTheCapMatchesEveryone() {
        for (int i = 1; i <= 8; i++) {
            donor("O-", i);
        }

        assertThat(matching.findFor("A+", hospital)).hasSize(8);
    }

    /**
     * ADR 0008 decision 4. Without the {@code id} tie-break the same request re-run in a demo would
     * alert a different set, in a different order, for no visible reason.
     */
    @Test
    void twoIdenticalRunsReturnTheSameDonorsInTheSameOrder() {
        for (int i = 1; i <= 12; i++) {
            // All at the same distance, so only the tie-break can decide the order.
            donor("O-", 3);
        }

        List<UUID> first =
                matching.findFor("A+", hospital).stream()
                        .map(MatchingService.Candidate::donorProfileId)
                        .toList();
        List<UUID> second =
                matching.findFor("A+", hospital).stream()
                        .map(MatchingService.Candidate::donorProfileId)
                        .toList();

        assertThat(first).isEqualTo(second).hasSize(12);
    }

    @Test
    void donorsAreRankedNearestFirst() {
        UUID far = donor("O-", 6);
        UUID near = donor("O-", 1);
        UUID middle = donor("O-", 3);

        assertThat(matching.findFor("A+", hospital))
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(near, middle, far);
    }

    /**
     * ADR 0003: declining GPS must never cost a donor a match. And {@code NULLS LAST} is
     * load-bearing — Postgres sorts NULL first on ASC, so without it this donor would lead the
     * alert list instead of trailing it.
     */
    @Test
    void aDonorWithNoCoordinatesIsMatchedAndSortsLast() {
        UUID noCoordinates = donor("O-", 0, true, null, false);
        UUID far = donor("O-", 9);

        List<MatchingService.Candidate> matched = matching.findFor("A+", hospital);

        assertThat(matched)
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(far, noCoordinates);
        assertThat(matched.get(1).distanceKm()).isNull();
    }

    /** Default radius is 10 km (prd.md FR-05). FR-MATCH-002 is deferred, so nothing widens it. */
    @Test
    void aDonorBeyondTheRadiusIsNotMatched() {
        UUID inside = donor("O-", 9);
        UUID outside = donor("O-", 40);

        assertThat(matching.findFor("A+", hospital))
                .extracting(MatchingService.Candidate::donorProfileId)
                .containsExactly(inside)
                .doesNotContain(outside);
    }

    /** ADR 0003: every distance the system produces is already rounded to 0.5 km. */
    @Test
    void distanceIsRoundedToHalfAKilometre() {
        donor("O-", 3);

        BigDecimal distance = matching.findFor("A+", hospital).get(0).distanceKm();

        assertThat(distance.remainder(new BigDecimal("0.5"))).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ---------------------------------------------------------------------

    private UUID donor(String bloodType, int kmNorth) {
        return donor(bloodType, kmNorth, true, null, true);
    }

    private UUID donor(
            String bloodType,
            int kmNorth,
            boolean available,
            LocalDate lastDonation,
            boolean withCoordinates) {

        String uid = "uid-" + UUID.randomUUID();
        jdbc.update("INSERT INTO users (firebase_uid, role) VALUES (?, 'DONOR')", uid);
        UUID userId =
                jdbc.queryForObject("SELECT id FROM users WHERE firebase_uid = ?", UUID.class, uid);

        BigDecimal latitude =
                withCoordinates
                        ? HOSPITAL_LAT
                                .add(BigDecimal.valueOf(kmNorth * KM_IN_DEGREES))
                                .setScale(5, java.math.RoundingMode.HALF_UP)
                        : null;
        BigDecimal longitude = withCoordinates ? HOSPITAL_LNG : null;

        jdbc.update(
                "INSERT INTO donor_profiles (user_id, full_name, blood_type, district_code,"
                        + " is_available, last_donation_date, latitude, longitude)"
                        + " VALUES (?, 'Test Donor', ?, '1204', ?, ?, ?, ?)",
                userId,
                bloodType,
                available,
                lastDonation,
                latitude,
                longitude);

        return jdbc.queryForObject(
                "SELECT id FROM donor_profiles WHERE user_id = ?", UUID.class, userId);
    }
}
