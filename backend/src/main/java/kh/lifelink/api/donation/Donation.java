package kh.lifelink.api.donation;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * The sole source of truth for eligibility. {@code donorProfile.lastDonationDate} is only a cache
 * of {@code MAX(donated_on)}; when the two disagree, this row wins.
 *
 * <p>Has {@code created_at} but no {@code updated_at} — a recorded donation is history, not a
 * mutable record — so it does not extend {@code Auditable}.
 */
@Entity
@Table(name = "donations")
public class Donation {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "donor_profile_id", nullable = false)
    private UUID donorProfileId;

    @Column(name = "hospital_id", nullable = false)
    private UUID hospitalId;

    /** Nullable per FR-08 — a walk-in donation has no originating request. */
    @Column(name = "blood_request_id")
    private UUID bloodRequestId;

    /** Drives the 56-day cooldown (FR-DONOR-002). */
    @Column(name = "donated_on", nullable = false)
    private LocalDate donatedOn;

    /** The hospital staff member who confirmed it (FR-08). */
    @Column(name = "confirmed_by_user_id")
    private UUID confirmedByUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    void onInsert() {
        this.createdAt = OffsetDateTime.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getDonorProfileId() {
        return donorProfileId;
    }

    public void setDonorProfileId(UUID donorProfileId) {
        this.donorProfileId = donorProfileId;
    }

    public UUID getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(UUID hospitalId) {
        this.hospitalId = hospitalId;
    }

    public UUID getBloodRequestId() {
        return bloodRequestId;
    }

    public void setBloodRequestId(UUID bloodRequestId) {
        this.bloodRequestId = bloodRequestId;
    }

    public LocalDate getDonatedOn() {
        return donatedOn;
    }

    public void setDonatedOn(LocalDate donatedOn) {
        this.donatedOn = donatedOn;
    }

    public UUID getConfirmedByUserId() {
        return confirmedByUserId;
    }

    public void setConfirmedByUserId(UUID confirmedByUserId) {
        this.confirmedByUserId = confirmedByUserId;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
