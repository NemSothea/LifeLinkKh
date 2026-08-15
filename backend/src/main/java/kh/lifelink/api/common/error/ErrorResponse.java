package kh.lifelink.api.common.error;

/**
 * The single error shape every endpoint returns. The {@code error} envelope is required by {@code
 * components/schemas/Error} in both OpenAPI documents; on any conflict between the code and that
 * schema, the schema wins. Kept deliberately thin — no stack trace, no exception class name, no
 * timestamp, nothing that describes the server to a caller.
 */
public record ErrorResponse(Detail error) {

    /** The stable, client-switchable {@code code} and its human-readable {@code message}. */
    public record Detail(String code, String message) {}

    public static ErrorResponse of(String code, String message) {
        return new ErrorResponse(new Detail(code, message));
    }
}
