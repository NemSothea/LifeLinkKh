package kh.lifelink.api.district;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

/**
 * A Phnom Penh khan. Reference data, seeded by migration — the application never writes this table.
 *
 * <p>Does not extend {@code Auditable}: the table has {@code created_at} but no {@code updated_at},
 * because a row that changes is a different district.
 */
@Entity
@Table(name = "districts")
public class District {

    /** National geocode — province 12 plus a two-digit district. */
    @Id
    @Column(name = "code", nullable = false, updatable = false, length = 16)
    private String code;

    /** Primary label. The app defaults to km (FR-GLOBAL-001). */
    @Column(name = "name_km", nullable = false, length = 80)
    private String nameKm;

    @Column(name = "name_en", nullable = false, length = 80)
    private String nameEn;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public String getCode() {
        return code;
    }

    public String getNameKm() {
        return nameKm;
    }

    public String getNameEn() {
        return nameEn;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
