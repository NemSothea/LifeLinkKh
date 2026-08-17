package kh.lifelink.api.common.error;

import org.springframework.http.HttpStatus;

/**
 * A failure the caller is allowed to know about, carrying the status and the stable {@code code}
 * the client switches on.
 *
 * <p>Everything else becomes a 500 with {@code INTERNAL_ERROR} in {@link GlobalExceptionHandler}.
 * The split is the point: a message only reaches a client if someone deliberately wrote it here.
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public ApiException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public static ApiException notFound(String code, String message) {
        return new ApiException(HttpStatus.NOT_FOUND, code, message);
    }

    /** Syntactically fine, semantically refused — a bad blood type, a future donation date. */
    public static ApiException unprocessable(String code, String message) {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, code, message);
    }

    public static ApiException badRequest(String code, String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, code, message);
    }

    public static ApiException unauthorized(String code, String message) {
        return new ApiException(HttpStatus.UNAUTHORIZED, code, message);
    }

    public static ApiException rateLimited(String code, String message) {
        return new ApiException(HttpStatus.TOO_MANY_REQUESTS, code, message);
    }

    /**
     * The identity provider is not configured in this environment. Distinct from a 500 on purpose:
     * nothing is broken, the deployment is incomplete.
     */
    public static ApiException providerUnavailable(String code, String message) {
        return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, code, message);
    }
}
