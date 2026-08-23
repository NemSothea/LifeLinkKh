package kh.lifelink.api.telegram.dto;

/**
 * @param role honoured only when this chat has no account yet; ignored entirely for a returning
 *     one. Validated against the self-service allow-list in the service, not here — same reasoning
 *     as {@code GoogleSignInRequest} (TM-AUTH-002 E1, mirroring TM-AUTH-001 E1).
 */
public record TelegramStartRequest(String role) {}
