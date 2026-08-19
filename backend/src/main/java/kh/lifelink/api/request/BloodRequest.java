package kh.lifelink.api.request;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import kh.lifelink.api.common.audit.Auditable;

/**
 * An urgent need posted by a family or by hospital staff.
 *
 * <p>{@code status} accepts EXPIRED because FR-04 lists it, but <strong>nothing in the system can
 * set it</strong>, and that is now a settled answer rather than an open one: FR-REQUEST-005 is
 * deferred (docs/scope.md, DEC-004), so there is no expiry rule, no {@code expires_at} column and
 * no scheduled job. Requests are closed manually. EXPIRED stays a dead value, like WITHDRAWN on
 * {@code request_matches}.
 */
@Entity
@Table(name = "blood_requests")
public class BloodRequest extends Auditable {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    /** The requester, or the hospital staff member who posted on their behalf. */
    @Column(name = "created_by_user_id", nullable = false)
    private UUID createdByUserId;

    @Column(name = "hospital_id", nullable = false)
    private UUID hospitalId;

    /** One of A+, A-, B+, B-, AB+, AB-, O+, O- — enforced by a CHECK constraint. */
    @Column(name = "patient_blood_type", nullable = false, length = 3)
    private String patientBloodType;

    @Column(name = "units_needed", nullable = false)
    private Short unitsNeeded;

    /** CRITICAL, URGENT or ROUTINE. */
    @Column(name = "urgency", nullable = false, length = 16)
    private String urgency;

    /** OPEN, FULFILLED, CANCELLED or EXPIRED (unreachable at M2). */
    @Column(name = "status", nullable = false, length = 16)
    private String status = "OPEN";

    /**
     * The two contact fields are the payoff of the whole accept flow, and they are shown to a donor
     * <strong>only</strong> once that donor's own match response is ACCEPTED (TM-AUTH-001 I1). They
     * live on the request rather than on the account because the person posting may be posting for
     * someone else — see {@code V5__request_contact.sql}.
     */
    @Column(name = "contact_name", nullable = false, length = 120)
    private String contactName;

    /** Unverified. Nothing in this build verifies a phone number (ADR 0002). */
    @Column(name = "contact_phone", nullable = false, length = 20)
    private String contactPhone;

    public UUID getId() {
        return id;
    }

    public UUID getCreatedByUserId() {
        return createdByUserId;
    }

    public void setCreatedByUserId(UUID createdByUserId) {
        this.createdByUserId = createdByUserId;
    }

    public UUID getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(UUID hospitalId) {
        this.hospitalId = hospitalId;
    }

    public String getPatientBloodType() {
        return patientBloodType;
    }

    public void setPatientBloodType(String patientBloodType) {
        this.patientBloodType = patientBloodType;
    }

    public Short getUnitsNeeded() {
        return unitsNeeded;
    }

    public void setUnitsNeeded(Short unitsNeeded) {
        this.unitsNeeded = unitsNeeded;
    }

    public String getUrgency() {
        return urgency;
    }

    public void setUrgency(String urgency) {
        this.urgency = urgency;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getContactName() {
        return contactName;
    }

    public void setContactName(String contactName) {
        this.contactName = contactName;
    }

    public String getContactPhone() {
        return contactPhone;
    }

    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }
}
