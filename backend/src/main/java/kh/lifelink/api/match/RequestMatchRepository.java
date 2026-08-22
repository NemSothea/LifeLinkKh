package kh.lifelink.api.match;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequestMatchRepository extends JpaRepository<RequestMatch, UUID> {

    /** A donor's inbox. */
    List<RequestMatch> findByDonorProfileId(UUID donorProfileId);

    List<RequestMatch> findByBloodRequestId(UUID bloodRequestId);

    /** The portal's `acceptedDonors` list — only donors who answered, never the silent majority. */
    List<RequestMatch> findByBloodRequestIdAndResponse(UUID bloodRequestId, String response);

    /** Backs {@code alertedCount} — rows written, which is not the same as pushes delivered. */
    int countByBloodRequestId(UUID bloodRequestId);

    /** Backs {@code acceptedCount}. Computed on read; there is no counter column to drift. */
    int countByBloodRequestIdAndResponse(UUID bloodRequestId, String response);

    /**
     * The visibility check behind {@code GET /requests/{id}}: a donor may read a request they were
     * matched to, and the presence of this row is the whole authorisation rule.
     */
    Optional<RequestMatch> findByBloodRequestIdAndDonorProfileId(
            UUID bloodRequestId, UUID donorProfileId);
}
