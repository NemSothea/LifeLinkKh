package kh.lifelink.api.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import kh.lifelink.api.common.audit.Auditable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * An account. Constrained string values are validated by CHECK constraints in {@code V1__init.sql}
 * — the database is the single authority for them, so they are not duplicated as Java enums.
 *
 * <ul>
 *   <li>{@code role} — DONOR, REQUESTER, HOSPITAL, ADMIN. Self-service sign-up may only produce
 *       DONOR or REQUESTER; enforced server-side (TM-AUTH-001 E1).
 *   <li>{@code language} — km, en.
 * </ul>
 */
@Entity
@Table(name = "users")
public class User extends Auditable {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    /**
     * The Google {@code sub} from a verified ID token — the credential. MUST be written server-side
     * only, never bound from a request body (TM-AUTH-001 S1).
     *
     * <p>Nullable since {@code V11__telegram_auth.sql} — a Telegram-only account has no Google
     * identity at all. {@code users_has_a_credential_check} is what stops that relaxation from
     * producing an account with neither.
     */
    @Column(name = "firebase_uid", unique = true, length = 128)
    private String firebaseUid;

    /**
     * The Telegram chat id — the credential for a Telegram-authenticated account, exactly as {@code
     * firebaseUid} is for Google. Written only from an already-verified webhook call (TM-AUTH-002
     * S1/S2), never bound from a request body.
     */
    @Column(name = "telegram_chat_id", unique = true)
    private Long telegramChatId;

    /** E.164. UNVERIFIED since auth moved off OTP (ADR 0002). Nullable. */
    @Column(name = "phone", unique = true, length = 20)
    private String phone;

    @Column(name = "role", nullable = false, length = 16)
    private String role;

    /**
     * From the verified Google ID token, refreshed on every sign-in (TM-AUTH-001 E1). Lets an ADMIN
     * pick the right account out of a list when promoting someone to HOSPITAL/ADMIN — the one thing
     * a bare {@code firebase_uid} can't do. Never email or phone.
     */
    @Column(name = "display_name", length = 120)
    private String displayName;

    /**
     * PostgreSQL reports a {@code CHAR(2)} column as {@code bpchar}, which Hibernate reads as
     * {@code Types.CHAR}. Without this annotation Hibernate expects {@code VARCHAR} and {@code
     * ddl-auto=validate} refuses to start. Caught by SchemaIntegrationTest in CI.
     */
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "language", nullable = false, length = 2)
    private String language = "km";

    /** Registered at M3 (DEC-002). */
    @Column(name = "fcm_token", columnDefinition = "text")
    private String fcmToken;

    /**
     * Which hospital a HOSPITAL-role account is staff for (FR-PORTAL-001). NULL for every other
     * role, and for ADMIN — an admin is not scoped to one hospital.
     */
    @Column(name = "hospital_id")
    private UUID hospitalId;

    public UUID getId() {
        return id;
    }

    public String getFirebaseUid() {
        return firebaseUid;
    }

    public void setFirebaseUid(String firebaseUid) {
        this.firebaseUid = firebaseUid;
    }

    public Long getTelegramChatId() {
        return telegramChatId;
    }

    public void setTelegramChatId(Long telegramChatId) {
        this.telegramChatId = telegramChatId;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public UUID getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(UUID hospitalId) {
        this.hospitalId = hospitalId;
    }
}
