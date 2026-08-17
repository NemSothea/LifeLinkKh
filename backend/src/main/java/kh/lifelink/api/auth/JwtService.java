package kh.lifelink.api.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import kh.lifelink.api.common.error.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Issues and parses our own session JWT. Separate from Google's token entirely: the Google ID token
 * is exchanged once at {@code /auth/google} and is never accepted again on any endpoint
 * (TM-AUTH-001 S3).
 *
 * <p>Claims are the minimum that authorises a request — subject, role, issued-at, expiry. No phone,
 * no email, no display name: a JWT is readable by anyone holding it, so every claim is data
 * published to whoever ends up with the token.
 *
 * <p>The subject is our internal {@code users.id}, not the Google {@code sub}. Our tokens address
 * our own identity space, so a change of identity provider does not change what a token means.
 */
@Service
public class JwtService {

    public static final String ROLE_CLAIM = "role";

    private final SecretKey key;
    private final Duration lifetime;

    JwtService(
            @Value("${lifelink.jwt.secret}") String secret,
            @Value("${lifelink.jwt.lifetime}") Duration lifetime) {
        byte[] material = secret.getBytes(StandardCharsets.UTF_8);
        if (material.length < 32) {
            // HS256 with a key shorter than its output is a weak key, and jjwt would reject it at
            // first use — i.e. at a user's first sign-in rather than at startup.
            throw new IllegalStateException(
                    "lifelink.jwt.secret must be at least 32 bytes for HS256.");
        }
        this.key = io.jsonwebtoken.security.Keys.hmacShaKeyFor(material);
        this.lifetime = lifetime;
    }

    public String issue(UUID userId, String role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim(ROLE_CLAIM, role)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(lifetime)))
                .signWith(key)
                .compact();
    }

    /**
     * @throws ApiException 401 on any invalid, expired or unsigned token. The reason is not
     *     returned to the caller — "why" would tell an attacker which half of the token to change.
     */
    public Claims parse(String token) {
        try {
            return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        } catch (JwtException | IllegalArgumentException ex) {
            throw ApiException.unauthorized("INVALID_TOKEN", "Not authenticated.");
        }
    }

    public Duration getLifetime() {
        return lifetime;
    }
}
