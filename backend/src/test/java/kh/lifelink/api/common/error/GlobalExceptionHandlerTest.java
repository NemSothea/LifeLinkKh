package kh.lifelink.api.common.error;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
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
        assertThat(body.error().code()).isEqualTo("INTERNAL_ERROR");
        assertThat(body.error().message())
                .doesNotContain("postgres")
                .doesNotContain("IllegalStateException")
                .doesNotContain("5432");
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
        assertThat(response.getBody().error().code()).isEqualTo("VALIDATION_FAILED");
        assertThat(response.getBody().error().message()).isEqualTo("bloodType must not be blank");
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
        assertThat(response.getBody().error().message()).isEqualTo("request is invalid");
    }

    /**
     * A path no controller maps is the caller's mistake, not a server fault. Before this handler
     * existed it reached {@code onUnexpected} and answered 500, which told a client with a typo'd
     * URL that the backend was broken.
     */
    @Test
    void unmappedPath_isFourOhFourAndDoesNotEchoThePath() {
        ResponseEntity<ErrorResponse> response = handler.onNoResourceFound();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        ErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.error().code()).isEqualTo("NOT_FOUND");
        // The requested path is attacker-supplied; reflecting it is TM-AUTH-001 I2.
        assertThat(body.error().message()).isEqualTo("No such endpoint.");
    }

    /**
     * The contract test: the serialized JSON must be exactly the envelope declared by {@code
     * components/schemas/Error}, with no timestamp and no other top-level key.
     */
    @Test
    void serializesToTheEnvelopeTheOpenApiContractDeclares() throws Exception {
        String json =
                new ObjectMapper()
                        .writeValueAsString(
                                ErrorResponse.of(
                                        "VALIDATION_FAILED", "bloodType must not be blank"));

        assertThat(json)
                .isEqualTo(
                        "{\"error\":{\"code\":\"VALIDATION_FAILED\","
                                + "\"message\":\"bloodType must not be blank\"}}");
    }
}
