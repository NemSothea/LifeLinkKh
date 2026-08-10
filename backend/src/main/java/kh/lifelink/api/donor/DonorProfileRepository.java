package kh.lifelink.api.donor;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DonorProfileRepository extends JpaRepository<DonorProfile, UUID> {

    Optional<DonorProfile> findByUserId(UUID userId);
}
