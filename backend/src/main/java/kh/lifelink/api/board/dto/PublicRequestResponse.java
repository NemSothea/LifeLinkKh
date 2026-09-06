package kh.lifelink.api.board.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.hospital.dto.HospitalResponse;

/**
 * A row of the public live board — who needs blood, where, and when they asked.
 *
 * <p>Same counts as the portal's own row, computed the same way, because a number that differs
 * between the public page and the staff page is worse than no number. What is absent is the point:
 * no {@code contact_name} or {@code contact_phone} (revealed only to a donor who accepted, and that
 * rule was not part of {@code DEC-009}), and no coordinates anywhere (ADR 0003).
 */
public record PublicRequestResponse(
        UUID id,
        String patientBloodType,
        int unitsNeeded,
        String urgency,
        String status,
        HospitalResponse hospital,
        int alertedCount,
        int acceptedCount,
        OffsetDateTime createdAt,
        List<PublicDonorResponse> acceptedDonors) {}
