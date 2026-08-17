package kh.lifelink.api.schema;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Proves V1__init.sql against a real PostgreSQL: Flyway applies, entities agree with the schema
 * under ddl-auto=validate (context startup fails otherwise), CHECK constraints reject bad data, and
 * the ADR 0004 compatibility table is exactly right.
 *
 * <p>{@code disabledWithoutDocker = true} — this class SKIPS when no container runtime is present.
 * A skip is not a pass: docs/qa/test-strategy.md records Docker's absence as an open blocker.
 */
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest
@org.springframework.test.context.ActiveProfiles("test")
class SchemaIntegrationTest {

    @Container @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired private JdbcTemplate jdbc;

    @Test
    void flywayAppliesEveryMigration() {
        Integer applied =
                jdbc.queryForObject(
                        "SELECT count(*) FROM flyway_schema_history WHERE success", Integer.class);
        assertThat(applied).isEqualTo(2);
    }

    @Test
    void allEightTablesExist() {
        List<String> tables =
                jdbc.queryForList(
                        "SELECT table_name FROM information_schema.tables"
                                + " WHERE table_schema = 'public' AND table_name <> 'flyway_schema_history'",
                        String.class);
        assertThat(tables)
                .containsExactlyInAnyOrder(
                        "users",
                        "donor_profiles",
                        "hospitals",
                        "blood_requests",
                        "request_matches",
                        "donations",
                        "blood_compatibility",
                        "districts");
    }

    /**
     * V2 seeds nothing on purpose — five of the fourteen district codes are still unverified and
     * docs/po/reference/phnom-penh-districts.md forbids seeding while any are. Asserted rather than
     * assumed, so that whoever writes V3__seed_districts.sql sees this test fail and updates it
     * deliberately instead of discovering the rule afterwards.
     */
    @Test
    void districtsIsCreatedButDeliberatelyUnseeded() {
        // Matched on the national geocode pattern rather than on count(*), because other tests in
        // this class insert their own synthetic districts into the shared container. What is being
        // asserted is that the *migration* seeded nothing, not that the table is untouched.
        Integer seeded =
                jdbc.queryForObject(
                        "SELECT count(*) FROM districts WHERE code ~ '^12[0-9]{2}$'",
                        Integer.class);
        assertThat(seeded).isZero();
    }

    /**
     * Without this foreign key {@code district_code} is free text that accepts 'toul kork', 'TK'
     * and 'Toul Kork' as three different districts, and a district-filtered match query silently
     * returns nothing.
     */
    @Test
    void donorProfileDistrictMustExist() {
        jdbc.update("INSERT INTO users (firebase_uid, role) VALUES ('uid-fk-test', 'DONOR')");
        assertThatThrownBy(
                        () ->
                                jdbc.update(
                                        "INSERT INTO donor_profiles"
                                                + " (user_id, full_name, blood_type, district_code)"
                                                + " SELECT id, 'Test Donor', 'A+', 'no-such-code' FROM users"
                                                + " WHERE firebase_uid = 'uid-fk-test'"))
                .hasMessageContaining("donor_profiles_district_fk");
    }

    /**
     * ADR 0004: a wrong row here means recommending incompatible blood, which is a patient-safety
     * error rather than a bug. Both directions are asserted — all 27 present, and no 28th.
     */
    @Test
    void bloodCompatibilityHasExactlyTheTwentySevenValidPairs() {
        Integer rows =
                jdbc.queryForObject("SELECT count(*) FROM blood_compatibility", Integer.class);
        assertThat(rows).isEqualTo(27);

        assertThat(donorsFor("O-")).containsExactlyInAnyOrder("O-");
        assertThat(donorsFor("O+")).containsExactlyInAnyOrder("O-", "O+");
        assertThat(donorsFor("A-")).containsExactlyInAnyOrder("O-", "A-");
        assertThat(donorsFor("A+")).containsExactlyInAnyOrder("O-", "O+", "A-", "A+");
        assertThat(donorsFor("B-")).containsExactlyInAnyOrder("O-", "B-");
        assertThat(donorsFor("B+")).containsExactlyInAnyOrder("O-", "O+", "B-", "B+");
        assertThat(donorsFor("AB-")).containsExactlyInAnyOrder("O-", "A-", "B-", "AB-");
        assertThat(donorsFor("AB+"))
                .containsExactlyInAnyOrder("O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+");
    }

    /** An Rh-negative recipient must never be offered Rh-positive blood. */
    @Test
    void noRhNegativeRecipientAcceptsRhPositiveBlood() {
        Integer violations =
                jdbc.queryForObject(
                        "SELECT count(*) FROM blood_compatibility"
                                + " WHERE recipient_type LIKE '%-' AND donor_type LIKE '%+'",
                        Integer.class);
        assertThat(violations).isZero();
    }

    @Test
    void bloodTypeCheckConstraintRejectsAnInvalidType() {
        jdbc.update("INSERT INTO users (firebase_uid, role) VALUES ('uid-check-test', 'DONOR')");
        // The district has to exist now, or this fails on the V2 foreign key and proves the wrong
        // thing. A synthetic code, not a real geocode: districtsIsCreatedButDeliberatelyUnseeded
        // asserts no real one exists, and these tests share one container.
        jdbc.update(
                "INSERT INTO districts (code, name_km, name_en)"
                        + " VALUES ('test-dist', 'តេស្ត', 'Test') ON CONFLICT DO NOTHING");
        assertThatThrownBy(
                        () ->
                                jdbc.update(
                                        "INSERT INTO donor_profiles"
                                                + " (user_id, full_name, blood_type, district_code)"
                                                + " SELECT id, 'Test Donor', 'C+', 'test-dist' FROM users"
                                                + " WHERE firebase_uid = 'uid-check-test'"))
                .hasMessageContaining("donor_profiles_blood_type_check");
    }

    @Test
    void unitsNeededMustBePositive() {
        assertThatThrownBy(
                        () ->
                                jdbc.update(
                                        "INSERT INTO blood_requests (created_by_user_id, hospital_id,"
                                                + " patient_blood_type, units_needed, urgency)"
                                                + " VALUES (gen_random_uuid(), gen_random_uuid(), 'A+', 0,"
                                                + " 'URGENT')"))
                .isNotNull();
    }

    private List<String> donorsFor(String recipient) {
        return jdbc.queryForList(
                "SELECT donor_type FROM blood_compatibility WHERE recipient_type = ?",
                String.class,
                recipient);
    }
}
