package kh.lifelink.api.common.error;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

/**
 * An error body must never describe the server. These assert the shape, not the wording — the
 * wording is allowed to change, leaking internals is not.
 */
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void unexpectedException_isFiveHundredWithNoServerDetail() {
        ResponseEntity<ErrorResponse> response =
                handler.onUnexpected(
                        new IllegalStateException("connection to postgres:5432 refused"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        ErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.code()).isEqualTo("INTERNAL_ERROR");
        assertThat(body.message())
                .doesNotContain("postgres")
                .doesNotContain("IllegalStateException")
                .doesNotContain("5432");
        assertThat(body.timestamp()).isNotNull();
    }

    @Test
    void validationFailure_isFourHundredAndNamesTheFirstBadField() {
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult binding = mock(BindingResult.class);
        when(ex.getBindingResult()).thenReturn(binding);
        when(binding.getFieldErrors())
                .thenReturn(List.of(new FieldError("donor", "bloodType", "must not be blank")));

        ResponseEntity<ErrorResponse> response = handler.onValidationFailure(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().code()).isEqualTo("VALIDATION_FAILED");
        assertThat(response.getBody().message()).isEqualTo("bloodType must not be blank");
    }

    @Test
    void validationFailure_withNoFieldError_stillReturnsAUsableMessage() {
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult binding = mock(BindingResult.class);
        when(ex.getBindingResult()).thenReturn(binding);
        when(binding.getFieldErrors()).thenReturn(List.of());

        ResponseEntity<ErrorResponse> response = handler.onValidationFailure(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().message()).isEqualTo("request is invalid");
    }

    @Test
    void errorResponse_carriesCodeMessageAndTimestamp() {
        ErrorResponse error = ErrorResponse.of("VALIDATION_FAILED", "bloodType must not be blank");

        assertThat(error.code()).isEqualTo("VALIDATION_FAILED");
        assertThat(error.message()).isEqualTo("bloodType must not be blank");
        assertThat(error.timestamp()).isNotNull();
    }
}
