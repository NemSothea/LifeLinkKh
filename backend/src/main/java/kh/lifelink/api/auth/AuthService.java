package kh.lifelink.api.auth;

import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Verify, find-or-create, issue. */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /**
     * TM-AUTH-001 E1. Self-service sign-up may produce only these two. {@code HOSPITAL} and {@code
     * ADMIN} are provisioned by an existing admin, and an attempt to claim one is **rejected, never
     * downgraded** — a silent downgrade turns a privilege-escalation attempt into a successful
     * signup and destroys the only signal that anyone tried.
     */
    private static final Set<String> SELF_SERVICE_ROLES = Set.of("DONOR", "REQUESTER");

    private static final String DEFAULT_ROLE = "DONOR";

    private final GoogleTokenVerifier verifier;
    private final UserRepository users;
    private final JwtService jwt;

    AuthService(GoogleTokenVerifier verifier, UserRepository users, JwtService jwt) {
        this.verifier = verifier;
        this.users = users;
        this.jwt = jwt;
    }

    @Transactional
    public AuthResponse signIn(String idToken, String requestedRole) {
        GoogleTokenVerifier.VerifiedIdentity identity = verifier.verify(idToken);

        return users.findByFirebaseUid(identity.uid())
                .map(existing -> signInExisting(existing, identity))
                .orElseGet(() -> createAccount(identity, requestedRole));
    }

    private AuthResponse signInExisting(
            User existing, GoogleTokenVerifier.VerifiedIdentity identity) {
        // `role` from the body is ignored outright for a returning user — not compared, not
        // validated. Changing role is not a self-service operation in this build.
        log.info("auth sign-in user={} outcome=RETURNING", existing.getId());
        return respond(existing, identity.displayName(), false);
    }

    private AuthResponse createAccount(
            GoogleTokenVerifier.VerifiedIdentity identity, String requestedRole) {
        String role = requestedRole == null ? DEFAULT_ROLE : requestedRole;
        if (!SELF_SERVICE_ROLES.contains(role)) {
            // Logged because a rejection is the signal. No user id exists to log — there is
            // deliberately no row.
            log.warn("auth sign-up rejected outcome=ROLE_NOT_SELF_SERVICE role={}", role);
            throw ApiException.unprocessable(
                    "ROLE_NOT_SELF_SERVICE", "That role cannot be chosen at sign-up.");
        }

        User user = new User();
        // From the verified token's sub claim and nowhere else (TM-AUTH-001 S1).
        user.setFirebaseUid(identity.uid());
        user.setRole(role);
        User saved = users.save(user);

        log.info("auth sign-up user={} outcome=CREATED role={}", saved.getId(), role);
        return respond(saved, identity.displayName(), true);
    }

    /** Writes the caller's FCM token. The target is the JWT subject, never a body field. */
    @Transactional
    public void registerFcmToken(UUID userId, String fcmToken) {
        User user = requireCaller(userId);
        // Idempotent by nature: the Firebase SDK rotates tokens on its own schedule and the client
        // re-posts whatever it currently holds, so the same value twice is a no-op, not an error.
        user.setFcmToken(fcmToken);
        log.info("fcm token registered user={}", userId);
    }

    /**
     * Clears the caller's FCM token at sign-out. Without this the session ends on the device while
     * the server keeps pushing urgent requests to it — the alert reaches whoever now holds the
     * phone (I2) and, worse, counts as a notified donor who will never answer.
     *
     * <p>Idempotent: signing out twice, or with no token ever registered, is a 204 either way. A
     * 404 would leak whether a row had a token, and there is nothing the client could do
     * differently.
     */
    @Transactional
    public void clearFcmToken(UUID userId) {
        User user = requireCaller(userId);
        user.setFcmToken(null);
        log.info("fcm token cleared user={}", userId);
    }

    /**
     * The JWT verified, but its subject has no row — the account was deleted mid-session. 401, not
     * 404: the token is no longer a valid credential, which is what the client has to act on.
     */
    private User requireCaller(UUID userId) {
        return users.findById(userId)
                .orElseThrow(
                        () -> ApiException.unauthorized("INVALID_TOKEN", "Not authenticated."));
    }

    private AuthResponse respond(User user, String displayName, boolean isNewAccount) {
        return new AuthResponse(
                jwt.issue(user.getId(), user.getRole()),
                new AuthResponse.AuthenticatedUser(
                        user.getId(), user.getRole(), displayName, isNewAccount));
    }
}
