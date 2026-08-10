package kh.lifelink.api.donor;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import kh.lifelink.api.common.audit.Auditable;

/**
 * Donor-only attributes, one per user at most.
 *
 * <p><strong>ADR 0003 — {@link #latitude} and {@link #longitude} MUST NEVER appear in an API
 * response.</strong> Not to the portal, not to the requester, not to admin. Distance is returned
 * pre-computed and rounded to 0.5 km; location is described by {@code districtCode}. Donor DTOs are
 * explicit allow-lists — this entity is never serialised directly.
 *
 * <p>Foreign keys are held as raw UUIDs rather than JPA associations at M2. That keeps the entity
 * un-navigable, so no accidental lazy-load can serialise a graph that reaches the coordinates
 * above.
 */
@Entity
@Table(name = "donor_profiles")
public class DonorProfile extends Auditable {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    /** One of A+, A-, B+, B-, AB+, AB-, O+, O- — enforced by a CHECK constraint. */
    @Column(name = "blood_type", nullable = false, length = 3)
    private String bloodType;

    /**
     * NULL means never donated. A cache of {@code MAX(donations.donated_on)} — if the two disagree,
     * the {@code donations} row wins.
     */
    @Column(name = "last_donation_date")
    private LocalDate lastDonationDate;

    @Column(name = "is_available", nullable = false)
    private boolean available = true;

    /** The only location value ever returned to another user (ADR 0003). */
    @Column(name = "district_code", nullable = false, length = 16)
    private String districtCode;

    /** Distance ranking only. Nullable on purpose — a donor who declines GPS still registers. */
    @Column(name = "latitude", precision = 8, scale = 5)
    private BigDecimal latitude;

    /** Distance ranking only. Nullable on purpose. */
    @Column(name = "longitude", precision = 8, scale = 5)
    private BigDecimal longitude;

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getBloodType() {
        return bloodType;
    }

    public void setBloodType(String bloodType) {
        this.bloodType = bloodType;
    }

    public LocalDate getLastDonationDate() {
        return lastDonationDate;
    }

    public void setLastDonationDate(LocalDate lastDonationDate) {
        this.lastDonationDate = lastDonationDate;
    }

    public boolean isAvailable() {
        return available;
    }

    public void setAvailable(boolean available) {
        this.available = available;
    }

    public String getDistrictCode() {
        return districtCode;
    }

    public void setDistrictCode(String districtCode) {
        this.districtCode = districtCode;
    }

    public BigDecimal getLatitude() {
        return latitude;
    }

    public void setLatitude(BigDecimal latitude) {
        this.latitude = latitude;
    }

    public BigDecimal getLongitude() {
        return longitude;
    }

    public void setLongitude(BigDecimal longitude) {
        this.longitude = longitude;
    }
}
