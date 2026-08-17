package kh.lifelink.api.auth;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.config.FirebaseConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * The production verifier. Delegates the cryptography to the Firebase Admin SDK, then adds the one
 * check the SDK does not make.
 *
 * <p>What the SDK covers (TM-AUTH-001 S1/S2/T1): RS256 pinned, Google's JWKS fetched and cached,
 * key rotation honoured, {@code exp} and {@code iat} checked, {@code aud} compared against the
 * project the SDK was initialised with.
 *
 * <p>What it does not cover: {@code iss}. Asserted below. A correctly-signed token minted for a
 * different Firebase project verifies cryptographically — that is the failure mode that looks like
 * success (S2), and it is why both {@code aud} and {@code iss} are checked rather than either.
 */
@Component
public class FirebaseGoogleTokenVerifier implements GoogleTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(FirebaseGoogleTokenVerifier.class);

    private final FirebaseConfig firebase;

    FirebaseGoogleTokenVerifier(FirebaseConfig firebase) {
        this.firebase = firebase;
    }

    @Override
    public VerifiedIdentity verify(String idToken) {
        if (!firebase.isAvailable()) {
            // The deployment is incomplete, not broken. Distinguishable from a 500 so an operator
            // reading a log knows to add credentials rather than to debug the code.
            throw ApiException.providerUnavailable(
                    "AUTH_PROVIDER_UNCONFIGURED", "Sign-in is unavailable.");
        }

        FirebaseToken token;
        try {
            token = FirebaseAuth.getInstance(firebase.requireApp()).verifyIdToken(idToken, true);
        } catch (FirebaseAuthException | IllegalArgumentException ex) {
            // Reason class only. Never the token that failed (TM-AUTH-001 I2).
            log.info("Google ID token rejected: {}", ex.getClass().getSimpleName());
            throw ApiException.unauthorized("INVALID_ID_TOKEN", "Sign-in failed.");
        }

        String expectedIssuer = "https://securetoken.google.com/" + firebase.getProjectId();
        Object issuer = token.getClaims().get("iss");
        if (!expectedIssuer.equals(issuer)) {
            // Reached only if the SDK's audience check and this disagree, which would mean the SDK
            // was initialised against a project other than the configured one.
            log.warn("Google ID token rejected: issuer mismatch");
            throw ApiException.unauthorized("INVALID_ID_TOKEN", "Sign-in failed.");
        }

        return new VerifiedIdentity(token.getUid(), token.getName());
    }
}
