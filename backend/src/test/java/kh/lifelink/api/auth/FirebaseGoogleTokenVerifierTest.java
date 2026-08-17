package kh.lifelink.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.config.FirebaseConfig;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

/**
 * The unconfigured path of the production verifier — the only part of it that can be tested before
 * the Firebase project exists, and the part most worth pinning.
 *
 * <p>The rest of {@link FirebaseGoogleTokenVerifier} delegates to {@code FirebaseAuth}, a static
 * factory over a live JWKS fetch. Faking that would test the fake. TC-AUTH-001 cases 3, 4 and 5
 * (foreign project, {@code alg:none}, RS256 re-signed as HS256) are therefore QA's to run against a
 * configured deployment; what is asserted here is that an unconfigured one cannot be talked into
 * accepting anything.
 */
class FirebaseGoogleTokenVerifierTest {

    /**
     * 503, not 500 and above all not a pass. The failure mode this guards against is the "helpful"
     * fallback — a verifier that trusts the token when the SDK is missing would turn an incomplete
     * deployment into an open authentication bypass, and every other test in the suite would still
     * be green.
     */
    @Test
    void anUnconfiguredSdkRefusesEveryTokenWith503() {
        FirebaseConfig unconfigured = mock(FirebaseConfig.class);
        when(unconfigured.isAvailable()).thenReturn(false);
        FirebaseGoogleTokenVerifier verifier = new FirebaseGoogleTokenVerifier(unconfigured);

        for (String token : new String[] {"", "junk", "eyJhbGciOiJub25lIn0.e30."}) {
            assertThatThrownBy(() -> verifier.verify(token))
                    .isInstanceOf(ApiException.class)
                    .satisfies(
                            ex -> {
                                assertThat(((ApiException) ex).getStatus())
                                        .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                                assertThat(((ApiException) ex).getCode())
                                        .isEqualTo("AUTH_PROVIDER_UNCONFIGURED");
                            });
        }
    }

    /** The message reaching the client says nothing about why. */
    @Test
    void theUnconfiguredMessageLeaksNothing() {
        FirebaseConfig unconfigured = mock(FirebaseConfig.class);
        when(unconfigured.isAvailable()).thenReturn(false);
        FirebaseGoogleTokenVerifier verifier = new FirebaseGoogleTokenVerifier(unconfigured);

        assertThatThrownBy(() -> verifier.verify("junk"))
                .hasMessage("Sign-in is unavailable.")
                .hasMessageNotContaining("credential")
                .hasMessageNotContaining("GOOGLE_APPLICATION_CREDENTIALS");
    }
}
