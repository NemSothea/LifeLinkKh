package kh.lifelink.api.request.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * The urgent-request form. Six fields, and FR-REQUEST-001's one-minute goal is a design constraint
 * on this record: the person filling it in is frightened and standing in a hospital corridor, so
 * anything optional is absent.
 *
 * @param contactName who the donor asks for on arrival (CR-MAPI-003)
 * @param contactPhone the callback number, revealed only after a donor accepts
 */
public record RequestCreateRequest(
        @NotBlank String patientBloodType,
        @NotNull @Min(1) Integer unitsNeeded,
        @NotNull UUID hospitalId,
        @NotBlank String urgency,
        @NotBlank @Size(max = 120) String contactName,
        @NotBlank @Size(max = 20) String contactPhone) {}
