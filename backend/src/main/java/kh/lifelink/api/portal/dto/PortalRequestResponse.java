package kh.lifelink.api.portal.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.hospital.dto.HospitalResponse;

/**
 * A row of the portal's one table. {@code alertedCount} and {@code acceptedCount} are the same
 * computed-on-read counts as the mobile contract's {@code BloodRequestResponse} — one meaning,
 * read by two clients, never two counters that can disagree.
 *
 * @param acceptedDonors donors who accepted and whose donation is <strong>not yet
 *     confirmed</strong> — never the alerted-but-silent rest ({@code TM-AUTH-001} I1), and no
 *     longer listed once {@code confirm-donation} has run for them, so this stays the actionable
 *     list rather than one with a "confirm" button that would only 409. {@code acceptedCount}
 *     still counts every acceptance, confirmed or not — same meaning as the mobile contract's.
 */
public record PortalRequestResponse(
        UUID id,
        String patientBloodType,
        int unitsNeeded,
        String urgency,
        String status,
        HospitalResponse hospital,
        int alertedCount,
        int acceptedCount,
        OffsetDateTime createdAt,
        List<AcceptedDonorResponse> acceptedDonors) {}
