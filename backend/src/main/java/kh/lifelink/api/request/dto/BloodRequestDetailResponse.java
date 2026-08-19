package kh.lifelink.api.request.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
import kh.lifelink.api.hospital.dto.HospitalResponse;

/**
 * A single request, as seen by its creator or by a donor matched to it.
 *
 * <p>Flat rather than wrapping {@link BloodRequestResponse}, because the contract composes it with
 * {@code allOf} and that serialises as one object. The duplication is deliberate and visible;
 * nesting would change the JSON shape.
 *
 * @param distanceKm rounded to 0.5 km in SQL (ADR 0003). Present only when the caller is a matched
 *     donor who has coordinates; null otherwise. There is no code path in the product that produces
 *     an unrounded donor distance.
 * @param requesterContact null unless the caller is a donor whose own match response is ACCEPTED.
 *     Null, not an empty object — a client bug should read as a crash, not as a contact card with
 *     blank fields.
 */
public record BloodRequestDetailResponse(
        UUID id,
        String status,
        String patientBloodType,
        int unitsNeeded,
        String urgency,
        HospitalResponse hospital,
        int alertedCount,
        int acceptedCount,
        OffsetDateTime createdAt,
        BigDecimal distanceKm,
        RequesterContact requesterContact) {}
