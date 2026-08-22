package kh.lifelink.api.request;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BloodRequestRepository extends JpaRepository<BloodRequest, UUID> {

    /** Backs the single hospital portal page for ADMIN, who sees every hospital (FR-PORTAL-001). */
    List<BloodRequest> findByStatusOrderByCreatedAtDesc(String status);

    /** Same page, scoped to one hospital — what a HOSPITAL-role account actually sees. */
    List<BloodRequest> findByStatusAndHospitalIdOrderByCreatedAtDesc(
            String status, UUID hospitalId);

    /**
     * {@code GET /requests/me} — newest first, because the one you just posted is the one you are
     * watching.
     */
    List<BloodRequest> findByCreatedByUserIdOrderByCreatedAtDesc(UUID createdByUserId);
}
