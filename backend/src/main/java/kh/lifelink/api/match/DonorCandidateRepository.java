package kh.lifelink.api.match;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.donor.DonorProfile;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * The matching query (FR-MATCH-001). One statement, deliberately.
 *
 * <p>The alternative — load candidate donors and rank them in Java — would pull every candidate's
 * coordinates into application heap to produce an ordering the database can produce itself. ADR
 * 0003's exposure argument is about API responses, but heap dumps and thread dumps are exposure
 * too, and there is no reason to accept it for nothing.
 *
 * <p>Read-only. This interface extends {@link Repository} rather than {@code JpaRepository} so it
 * exposes exactly one method and no {@code save}/{@code delete} surface for a table it has no
 * business writing.
 */
public interface DonorCandidateRepository extends Repository<DonorProfile, UUID> {

    /**
     * Compatible, available, eligible donors within the radius, nearest first.
     *
     * <p>Each clause is load-bearing:
     *
     * <ul>
     *   <li><strong>The compatibility join direction.</strong> {@code bc.recipient_type} is the
     *       patient and {@code bc.donor_type} is the donor. Swapping them compiles, runs, returns
     *       rows, and matches exactly the wrong people — an O− patient would be offered every donor
     *       in the city. ADR 0004 chose a table over branching code so this is a join, not eight
     *       {@code if}s; the direction is the one thing a table cannot protect.
     *   <li><strong>{@code last_donation_date} is read, not {@code donations}.</strong> {@code
     *       V1__init.sql} calls the column a cache of {@code MAX(donations.donated_on)} and says
     *       donations wins on disagreement. That is the right rule for the displayed value and the
     *       wrong thing to put in this query as a correlated subquery. If the two ever disagree the
     *       fix is the writer.
     *   <li><strong>{@code NULLS LAST}.</strong> Postgres sorts NULL first on {@code ASC}, so
     *       without this every donor who declined GPS leads the alert list — the exact inversion of
     *       "nearest first". A donor with no coordinates still matches (ADR 0003: declining GPS
     *       must not cost a match) and sorts last.
     *   <li><strong>The {@code id} tie-break.</strong> Two donors at the same rounded distance must
     *       not swap places between runs, or the same request re-run in a demo alerts a different
     *       set and nobody can explain why (ADR 0008).
     *   <li><strong>{@code least(1, ...)}.</strong> Floating-point can push the {@code acos}
     *       argument a hair above 1 for two points at the same place, which is a domain error, not
     *       a distance of zero.
     *   <li><strong>The explicit NULL guard around it.</strong> Postgres' {@code least}
     *       <em>skips</em> NULL arguments rather than propagating them, so {@code least(1, NULL)}
     *       is {@code 1} and {@code acos(1)} is {@code 0} — a donor who declined GPS would come
     *       back at 0.0 km and lead the alert list. That is the same inversion {@code NULLS LAST}
     *       exists to prevent, arriving through a different door, and {@code NULLS LAST} cannot
     *       catch it because the value is no longer null. Caught by MatchingIntegrationTest, which
     *       is why the ranking rules are tested against a real PostgreSQL and not a mock.
     * </ul>
     *
     * @param eligibleCutoff today minus {@link
     *     kh.lifelink.api.donor.EligibilityCalculator#COOLDOWN_DAYS}; a donor is eligible when they
     *     last donated on or before it
     * @param maxNotified ADR 0008's cap — a ceiling, never a target
     */
    @Query(
            value =
                    """
                    SELECT c.id                                AS "donorProfileId",
                           ROUND(c.distance_km::numeric * 2, 0) / 2 AS "distanceKm"
                    FROM (
                        SELECT dp.id,
                               dp.latitude,
                               CASE WHEN dp.latitude IS NULL OR dp.longitude IS NULL THEN NULL
                                    ELSE 6371 * acos(least(1,
                                        cos(radians(:hospitalLat)) * cos(radians(dp.latitude))
                                          * cos(radians(dp.longitude) - radians(:hospitalLng))
                                      + sin(radians(:hospitalLat)) * sin(radians(dp.latitude))
                                    ))
                               END AS distance_km
                        FROM donor_profiles dp
                        JOIN blood_compatibility bc
                          ON bc.donor_type = dp.blood_type
                         AND bc.recipient_type = :patientBloodType
                        WHERE dp.is_available = true
                          AND (dp.last_donation_date IS NULL
                               OR dp.last_donation_date <= :eligibleCutoff)
                    ) c
                    WHERE c.latitude IS NULL OR c.distance_km <= :radiusKm
                    ORDER BY "distanceKm" ASC NULLS LAST, c.id ASC
                    LIMIT :maxNotified
                    """,
            nativeQuery = true)
    List<Candidate> findCandidates(
            @Param("patientBloodType") String patientBloodType,
            @Param("hospitalLat") BigDecimal hospitalLat,
            @Param("hospitalLng") BigDecimal hospitalLng,
            @Param("eligibleCutoff") LocalDate eligibleCutoff,
            @Param("radiusKm") int radiusKm,
            @Param("maxNotified") int maxNotified);

    /**
     * Aliases are quoted in the SQL above so Postgres preserves their case and these getters bind.
     * An unquoted {@code AS distanceKm} would be folded to {@code distancekm} and silently fail to
     * map.
     */
    interface Candidate {
        UUID getDonorProfileId();

        /** Rounded to 0.5 km in SQL (ADR 0003). Null when the donor has no coordinates. */
        BigDecimal getDistanceKm();
    }
}
