package kh.lifelink.api.donor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * {@code PUT /donors/me}. Create-or-update, keyed on the JWT subject — first call creates the row,
 * later calls update it, and the client does not distinguish. There is no {@code POST}.
 *
 * <p>Two fields are absent on purpose:
 *
 * <ul>
 *   <li><strong>{@code phone}</strong> — removed from FR-DONOR-001 on 2026-08-17 and struck from
 *       prd.md FR-02's required list. It has been unverified since ADR 0002 replaced phone OTP, and
 *       M3–M4 coordination runs over FCM push, so the app never reads it. {@code users.phone} stays
 *       in the schema, nullable and unused; do not add it here to "complete" the entity.
 *   <li><strong>{@code userId}</strong> — the row written is the caller's. There is no way to
 *       express any other intent (TM-AUTH-001 S1).
 * </ul>
 *
 * <p>Blood type, district existence and the future-date rule are checked in the service so each can
 * fail as a 422 with its own code, rather than collapsing into one generic binding error.
 *
 * <p><strong>{@code updateCoordinates}</strong> — CR-MAPI-004. No response ever echoes {@code
 * latitude}/{@code longitude} back (ADR 0003), so a client editing an existing profile has no way
 * to resend the coordinates it already has on file. Without this flag, every edit's {@code null}
 * coordinates would read as "clear them" and a donor changing their name would silently lose the
 * GPS precision that ranks them ahead of district-only donors. {@code true} means "apply {@code
 * latitude}/{@code longitude} below, including clearing them if both are null"; {@code false} or
 * absent means "leave whatever is stored alone."
 */
public record DonorProfileWriteRequest(
        @NotBlank @Size(max = 120) String fullName,
        @NotBlank String bloodType,
        @NotBlank String districtCode,
        BigDecimal latitude,
        BigDecimal longitude,
        LocalDate lastDonationDate,
        Boolean isAvailable,
        Boolean updateCoordinates) {}
