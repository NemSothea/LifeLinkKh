package kh.lifelink.api.request.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import kh.lifelink.api.hospital.dto.HospitalResponse;

/**
 * A request as its creator sees it in a list.
 *
 * @param alertedCount {@code request_matches} rows written — the number the waiting screen shows.
 *     <strong>Not</strong> pushes delivered: the two differ whenever a matched donor has no FCM
 *     token, and conflating them would flatter the PRD's ≥95% delivery metric with donors who were
 *     never sendable.
 * @param acceptedCount computed on read, never a counter column. A denormalised counter that
 *     disagrees with the rows is the classic version of this bug, and there is no volume here to
 *     justify one.
 */
public record BloodRequestResponse(
        UUID id,
        String status,
        String patientBloodType,
        int unitsNeeded,
        String urgency,
        HospitalResponse hospital,
        int alertedCount,
        int acceptedCount,
        OffsetDateTime createdAt) {}
