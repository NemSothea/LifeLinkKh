package kh.lifelink.api.match.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * ACCEPTED or DECLINED. WITHDRAWN is a column value with no FR behind it and is not accepted here.
 */
public record RespondRequest(@NotBlank String response) {}
