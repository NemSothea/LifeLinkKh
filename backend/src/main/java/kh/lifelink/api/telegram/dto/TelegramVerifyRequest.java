package kh.lifelink.api.telegram.dto;

import jakarta.validation.constraints.NotBlank;

public record TelegramVerifyRequest(@NotBlank String sessionToken, @NotBlank String code) {}
