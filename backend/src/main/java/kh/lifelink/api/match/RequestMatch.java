package kh.lifelink.api.match;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * One donor matched to one request. A real table, not a computed list — the match is the thing that
 * has state: whether a push was sent ({@code notifiedAt}) and what the donor answered.
 *
 * <p>Has no audit columns; {@code notifiedAt} and {@code respondedAt} are the timeline.
 */
@Entity
@Table(name = "request_matches")
public class RequestMatch {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "blood_request_id", nullable = false)
    private UUID bloodRequestId;

    @Column(name = "donor_profile_id", nullable = false)
    private UUID donorProfileId;

    /** Set when the FCM send succeeds (FR-NOTIFY-001). */
    @Column(name = "notified_at")
    private OffsetDateTime notifiedAt;

    /** ACCEPTED, DECLINED or WITHDRAWN. WITHDRAWN has a column but no FR yet. */
    @Column(name = "response", length = 16)
    private String response;

    @Column(name = "responded_at")
    private OffsetDateTime respondedAt;

    /**
     * How far this donor was when they were matched, rounded to 0.5 km (ADR 0003). NULL when the
     * donor had no coordinates. Written once and never recomputed — a donor who has since moved
     * would otherwise see their alert list re-rank itself under them.
     */
    @Column(name = "distance_km", precision = 4, scale = 1)
    private BigDecimal distanceKm;

    public UUID getId() {
        return id;
    }

    public UUID getBloodRequestId() {
        return bloodRequestId;
    }

    public void setBloodRequestId(UUID bloodRequestId) {
        this.bloodRequestId = bloodRequestId;
    }

    public UUID getDonorProfileId() {
        return donorProfileId;
    }

    public void setDonorProfileId(UUID donorProfileId) {
        this.donorProfileId = donorProfileId;
    }

    public OffsetDateTime getNotifiedAt() {
        return notifiedAt;
    }

    public void setNotifiedAt(OffsetDateTime notifiedAt) {
        this.notifiedAt = notifiedAt;
    }

    public String getResponse() {
        return response;
    }

    public void setResponse(String response) {
        this.response = response;
    }

    public OffsetDateTime getRespondedAt() {
        return respondedAt;
    }

    public void setRespondedAt(OffsetDateTime respondedAt) {
        this.respondedAt = respondedAt;
    }

    public BigDecimal getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(BigDecimal distanceKm) {
        this.distanceKm = distanceKm;
    }
}
