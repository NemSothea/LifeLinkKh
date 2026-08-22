// Dev-only: mints a session JWT identical in shape to JwtService.issue(), for a user id
// that already exists — e.g. the seeded HOSPITAL/ADMIN accounts from
// backend/src/main/resources/db/migration/V8__portal_access.sql.
//
// Interim bridge only, until a Firebase Web app is registered and the portal has a real
// Google Sign-In button — see docs/po/prototypes/web/PORTAL-open-requests/README.md.
// Not part of the Maven build; never referenced by any module.
//
// Usage:
//   cd backend
//   ./mvnw -q dependency:build-classpath -Dmdep.outputFile=/tmp/cp.txt
//   java -cp "target/classes:$(cat /tmp/cp.txt)" ../scripts/mint-portal-jwt.java \
//       "$JWT_SECRET" <userId> <role>
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;

public class MintPortalJwt {
    public static void main(String[] args) {
        String secret = args[0];
        String userId = args[1];
        String role = args[2];

        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        Instant now = Instant.now();
        String token =
                Jwts.builder()
                        .subject(userId)
                        .claim("role", role)
                        .issuedAt(Date.from(now))
                        .expiration(Date.from(now.plus(Duration.ofHours(1))))
                        .signWith(key)
                        .compact();
        System.out.println(token);
    }
}
