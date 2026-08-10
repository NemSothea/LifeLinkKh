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

    @ExceptionHandler(Exception.class)
    ResponseEntity<ErrorResponse> onUnexpected(Exception ex) {
        // The cause is logged, never returned — an error body must not describe the server.
        org.slf4j.LoggerFactory.getLogger(GlobalExceptionHandler.class)
                .error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of("INTERNAL_ERROR", "Something went wrong."));
    }
}
