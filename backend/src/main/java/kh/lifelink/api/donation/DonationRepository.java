package kh.lifelink.api.donation;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DonationRepository extends JpaRepository<Donation, UUID> {

    /** Donation history, newest first (FR-DONATION-001). */
    List<Donation> findByDonorProfileIdOrderByDonatedOnDesc(UUID donorProfileId);

    /** The cooldown lookup — authoritative over the cached last_donation_date (FR-DONOR-002). */
    Optional<Donation> findFirstByDonorProfileIdOrderByDonatedOnDesc(UUID donorProfileId);
}
