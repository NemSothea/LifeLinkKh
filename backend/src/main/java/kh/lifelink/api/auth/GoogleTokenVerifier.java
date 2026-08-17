package kh.lifelink.api.auth;

/**
 * Verifies a Google ID token and returns the identity it proves.
 *
 * <p>A deliberately thin seam. It is the one place the Firebase Admin SDK is touched, therefore the
 * one place tests mock, and the one place to change if ADR 0002's rejected Telegram fallback is
 * ever revisited.
 */
public interface GoogleTokenVerifier {

    /**
     * @return the verified identity — never anything the caller supplied
     * @throws kh.lifelink.api.common.error.ApiException 401 if the token is missing, malformed,
     *     expired, unsigned, or minted for a different Firebase project
     */
    VerifiedIdentity verify(String idToken);

    /**
     * The subject of a verified token. {@code uid} is the Google {@code sub} claim and nothing else
     * (TM-AUTH-001 S1).
     *
     * <p>No email field. Google sends one; we have no use for it, and storing it would make it a
     * breach asset.
     */
    record VerifiedIdentity(String uid, String displayName) {}
}
