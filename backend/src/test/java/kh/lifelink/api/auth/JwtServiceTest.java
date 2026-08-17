package kh.lifelink.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.Claims;
import java.time.Duration;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import org.junit.jupiter.api.Test;

class JwtServiceTest {

    private static final String SECRET = "test-secret-that-is-long-enough-for-hs256";

    private final JwtService jwt = new JwtService(SECRET, Duration.ofHours(1));

    @Test
    void aTokenRoundTripsItsSubjectAndRole() {
        UUID userId = UUID.randomUUID();

        Claims claims = jwt.parse(jwt.issue(userId, "DONOR"));

        assertThat(claims.getSubject()).isEqualTo(userId.toString());
        assertThat(claims.get(JwtService.ROLE_CLAIM, String.class)).isEqualTo("DONOR");
    }

    /**
     * A JWT is readable by whoever holds it, so every claim is data published to them. This pins
     * the claim set rather than the values — an added claim should fail a test, not slip out in a
     * response.
     */
    @Test
    void aTokenCarriesNothingBeyondSubjectRoleAndTimestamps() {
        Claims claims = jwt.parse(jwt.issue(UUID.randomUUID(), "DONOR"));

        assertThat(claims.keySet()).containsExactlyInAnyOrder("sub", "role", "iat", "exp");
    }

    /** A token signed with a different secret must not verify. */
    @Test
    void aTokenSignedWithAnotherSecretIsRejected() {
        JwtService other =
                new JwtService(
                        "a-completely-different-secret-of-sufficient-length", Duration.ofHours(1));
        String foreign = other.issue(UUID.randomUUID(), "DONOR");

        assertThatThrownBy(() -> jwt.parse(foreign)).isInstanceOf(ApiException.class);
    }

    @Test
    void anExpiredTokenIsRejected() {
        JwtService alreadyExpired = new JwtService(SECRET, Duration.ofSeconds(-1));
        String expired = alreadyExpired.issue(UUID.randomUUID(), "DONOR");

        assertThatThrownBy(() -> jwt.parse(expired)).isInstanceOf(ApiException.class);
    }

    @Test
    void garbageIsRejectedRatherThanThrowingSomethingUnhandled() {
        assertThatThrownBy(() -> jwt.parse("not-a-jwt")).isInstanceOf(ApiException.class);
    }

    /**
     * A short secret would otherwise be accepted here and rejected by jjwt at first use — that is,
     * at a user's first sign-in rather than at startup.
     */
    @Test
    void aSecretShorterThanHs256RequiresFailsFast() {
        assertThatThrownBy(() -> new JwtService("too-short", Duration.ofHours(1)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("32 bytes");
    }
}
