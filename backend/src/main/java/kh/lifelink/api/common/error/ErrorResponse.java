package kh.lifelink.api.common.error;

import java.time.OffsetDateTime;

/**
 * The single error shape every endpoint returns. Kept deliberately thin — no stack trace, no
 * exception class name, nothing that describes the server to a caller.
 */
public record ErrorResponse(String code, String message, OffsetDateTime timestamp) {

    public static ErrorResponse of(String code, String message) {
        return new ErrorResponse(code, message, OffsetDateTime.now());
    }
}
