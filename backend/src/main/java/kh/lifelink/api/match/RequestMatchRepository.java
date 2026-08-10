package kh.lifelink.api.match;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RequestMatchRepository extends JpaRepository<RequestMatch, UUID> {

    /** A donor's inbox. */
    List<RequestMatch> findByDonorProfileId(UUID donorProfileId);

    List<RequestMatch> findByBloodRequestId(UUID bloodRequestId);
}
