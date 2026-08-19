package kh.lifelink.api.hospital;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import kh.lifelink.api.common.audit.Auditable;

/**
 * A hospital's location is public information, not personal data, so full precision is stored and
 * it is not subject to the ADR 0003 response ban that applies to donor coordinates.
 */
@Entity
@Table(name = "hospitals")
public class Hospital extends Auditable {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "name", nullable = false, length = 160)
    private String name;

    @Column(name = "address", columnDefinition = "text")
    private String address;

    @Column(name = "contact_phone", length = 20)
    private String contactPhone;

    @Column(name = "latitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 9, scale = 6)
    private BigDecimal longitude;

    /**
     * Nullable, and the nullability is the interesting part. {@code V4__hospitals_district.sql}
     * added the column while the table was still empty, so there was no row to satisfy a NOT NULL.
     * References {@code districts(code)} — the foreign key is what stops it becoming free text.
     */
    @Column(name = "district_code", length = 16)
    private String districtCode;

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getContactPhone() {
        return contactPhone;
    }

    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
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

    public String getDistrictCode() {
        return districtCode;
    }

    public void setDistrictCode(String districtCode) {
        this.districtCode = districtCode;
    }
}
