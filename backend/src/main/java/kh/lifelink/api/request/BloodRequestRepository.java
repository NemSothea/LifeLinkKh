package kh.lifelink.api.request;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BloodRequestRepository extends JpaRepository<BloodRequest, UUID> {

    /** Backs the single hospital portal page (FR-PORTAL-001). */
    List<BloodRequest> findByStatusOrderByCreatedAtDesc(String status);
}
