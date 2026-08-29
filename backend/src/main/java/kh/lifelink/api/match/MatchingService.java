package kh.lifelink.api.match;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.donor.EligibilityCalculator;
import kh.lifelink.api.hospital.Hospital;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * FR-MATCH-001. Finds the donors who could genuinely answer a request, ranked by distance.
 *
 * <p>Everything interesting is in {@link DonorCandidateRepository}'s query. This class exists to
 * hold the two configured numbers and the cutoff arithmetic, so that neither is written twice and
 * neither is a literal in SQL.
 */
@Service
public class MatchingService {

    /**
     * One matched donor. {@code distanceKm} is already rounded to 0.5 km by the query — there is no
     * code path in the product that produces an unrounded donor distance (ADR 0003).
     */
    public record Candidate(UUID donorProfileId, BigDecimal distanceKm) {}

    private final DonorCandidateRepository candidates;
    private final Clock clock;
    private final int maxNotified;
    private final int radiusKm;

    MatchingService(
            DonorCandidateRepository candidates,
            Clock clock,
            @Value("${lifelink.matching.max-notified}") int maxNotified,
            @Value("${lifelink.matching.radius-km}") int radiusKm) {
        this.candidates = candidates;
        this.clock = clock;
        this.maxNotified = maxNotified;
        this.radiusKm = radiusKm;
    }

    /**
     * @param patientBloodType the recipient side of the compatibility join — not the donor side
     * @param requesterUserId excluded even when their own donor profile would otherwise qualify — a
     *     donor requesting blood for a relative must not be offered as a match for themselves
     * @return at most {@code lifelink.matching.max-notified} donors, nearest first, donors without
     *     coordinates last. Empty when nobody qualifies: there is no widening and no retry, because
     *     {@code FR-MATCH-002} is deferred (docs/scope.md).
     */
    @Transactional(readOnly = true)
    public List<Candidate> findFor(
            String patientBloodType, Hospital hospital, UUID requesterUserId) {
        LocalDate cutoff = LocalDate.now(clock).minusDays(EligibilityCalculator.COOLDOWN_DAYS);

        return candidates
                .findCandidates(
                        patientBloodType,
                        hospital.getLatitude(),
                        hospital.getLongitude(),
                        cutoff,
                        radiusKm,
                        maxNotified,
                        requesterUserId)
                .stream()
                .map(c -> new Candidate(c.getDonorProfileId(), c.getDistanceKm()))
                .toList();
    }
}
