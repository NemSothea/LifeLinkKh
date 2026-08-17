package kh.lifelink.api.common.error;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ErrorResponse> onValidationFailure(MethodArgumentNotValidException ex) {
        String detail =
                ex.getBindingResult().getFieldErrors().stream()
                        .findFirst()
                        .map(err -> err.getField() + " " + err.getDefaultMessage())
                        .orElse("request is invalid");
        return ResponseEntity.badRequest().body(ErrorResponse.of("VALIDATION_FAILED", detail));
    }

    /**
     * The only path by which a message we wrote reaches a client. Not logged at error level — a 404
     * or a rejected blood type is the API working, not a fault.
     */
    @ExceptionHandler(ApiException.class)
    ResponseEntity<ErrorResponse> onApiException(ApiException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(ErrorResponse.of(ex.getCode(), ex.getMessage()));
    }

    /**
     * A rejected write that violates a database constraint — the district foreign key is the one
     * that fires in this build. The constraint name and the SQL are deliberately not returned; they
     * describe the server (TM-AUTH-001 I2).
     */
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    ResponseEntity<ErrorResponse> onConstraintViolation(
            org.springframework.dao.DataIntegrityViolationException ex) {
        org.slf4j.LoggerFactory.getLogger(GlobalExceptionHandler.class)
                .warn("Constraint violation on write", ex);
        return ResponseEntity.unprocessableEntity()
                .body(
                        ErrorResponse.of(
                                "CONSTRAINT_VIOLATED", "A referenced value does not exist."));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ErrorResponse> onUnexpected(Exception ex) {
        // The cause is logged, never returned — an error body must not describe the server.
        org.slf4j.LoggerFactory.getLogger(GlobalExceptionHandler.class)
                .error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of("INTERNAL_ERROR", "Something went wrong."));
    }
}
