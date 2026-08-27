package kh.lifelink.api.telegram;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * One sign-in attempt in flight (TM-AUTH-002). Not extended from {@code Auditable} — this table has
 * {@code created_at} only, no {@code updated_at}, the same shape {@code donations} and {@code
 * request_matches} already use for a row nothing ever revises in place.
 */
@Entity
@Table(name = "telegram_auth_challenges")
public class TelegramAuthChallenge {

    @Id
    @GeneratedValue
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    /** Opaque, unguessable, generated server-side — never derived from anything client-supplied. */
    @Column(name = "session_token", nullable = false, unique = true, length = 64)
    private String sessionToken;

    /** Validated against the self-service allow-list at creation (TM-AUTH-002 E1). */
    @Column(name = "role", nullable = false, length = 16)
    private String role;

    /** Written only from a webhook call whose secret-token header already verified (S1/S2). */
    @Column(name = "chat_id")
    private Long chatId;

    /** SHA-256 of the 6-digit code. Never the code itself. */
    @Column(name = "otp_hash", length = 64)
    private String otpHash;

    /** From the webhook's {@code from.first_name}, applied to the user row in {@code verify()}. */
    @Column(name = "display_name", length = 120)
    private String displayName;

    @Column(name = "attempt_count", nullable = false)
    private short attemptCount;

    @Column(name = "otp_sent_at")
    private OffsetDateTime otpSentAt;

    @Column(name = "expires_at")
    private OffsetDateTime expiresAt;

    @Column(name = "consumed_at")
    private OffsetDateTime consumedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public UUID getId() {
        return id;
    }

    public String getSessionToken() {
        return sessionToken;
    }

    public void setSessionToken(String sessionToken) {
        this.sessionToken = sessionToken;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public Long getChatId() {
        return chatId;
    }

    public void setChatId(Long chatId) {
        this.chatId = chatId;
    }

    public String getOtpHash() {
        return otpHash;
    }

    public void setOtpHash(String otpHash) {
        this.otpHash = otpHash;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public short getAttemptCount() {
        return attemptCount;
    }

    public void incrementAttemptCount() {
        this.attemptCount++;
    }

    /** A fresh code (a resend) is a fresh row's worth of guess allowance. */
    public void resetAttemptCount() {
        this.attemptCount = 0;
    }

    public OffsetDateTime getOtpSentAt() {
        return otpSentAt;
    }

    public void setOtpSentAt(OffsetDateTime otpSentAt) {
        this.otpSentAt = otpSentAt;
    }

    public OffsetDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(OffsetDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public OffsetDateTime getConsumedAt() {
        return consumedAt;
    }

    public void setConsumedAt(OffsetDateTime consumedAt) {
        this.consumedAt = consumedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    @jakarta.persistence.PrePersist
    void onInsert() {
        this.createdAt = OffsetDateTime.now();
    }
}
