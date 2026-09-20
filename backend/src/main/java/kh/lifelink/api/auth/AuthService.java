package kh.lifelink.api.auth;

import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
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

    /** The only roles a username and password may ever sign in as. */
    private static final Set<String> PORTAL_ROLES = Set.of("HOSPITAL", "ADMIN");

    /**
     * A real BCrypt digest of a random string nobody holds, compared against when there is no row
     * or no stored hash. Without it, an unknown username returns in microseconds while a known one
     * takes the ~100ms BCrypt costs, and that difference alone enumerates the staff list. The
     * response was already identical; this makes the timing identical too.
     *
     * <p>It must be the digest of a value that is not a password anywhere. An earlier revision
     * reused the seeded admin's hash here, which meant a staff row with a NULL {@code
     * password_hash} authenticated successfully against the seeded password — a real hole, caught
     * by {@code anAccountWithNoPasswordHashCannotSignIn}. The structural guard below now refuses a
     * null hash regardless of what the comparison returns, so this value being wrong could never
     * again be enough on its own.
     */
    private static final String TIMING_DECOY_HASH =
            "$2a$10$gH01AwaU/BLto/QXKUnpl.JT3saq1gYEKk7uoI09cgshHWU7g3ou.";

    private final GoogleTokenVerifier verifier;
    private final UserRepository users;
    private final JwtService jwt;
    private final PasswordEncoder passwords;

    AuthService(
            GoogleTokenVerifier verifier,
            UserRepository users,
            JwtService jwt,
            PasswordEncoder passwords) {
        this.verifier = verifier;
        this.users = users;
        this.jwt = jwt;
        this.passwords = passwords;
    }

    /**
     * Portal sign-in. The one place in this product where a password is checked.
     *
     * <p>Every failure — unknown username, wrong password, an account whose role may not use this
     * door — answers the same 401 with the same code and takes the same time. A caller learns
     * whether they got the whole pair right and nothing else. That is why the role check is here
     * rather than at the controller: a distinguishable "you exist but you are a donor" response
     * would confirm an account for anyone who guessed a name.
     *
     * <p>Roles are checked against the row, never against anything the caller sent. There is no
     * requested-role parameter here for the same reason {@code /auth/google} ignores one for a
     * returning user: role is granted by an admin, never claimed at sign-in.
     */
    @Transactional(readOnly = true)
    public AuthResponse signInWithPassword(String username, String password) {
        User user = users.findByUsername(username).orElse(null);
        String storedHash = user == null ? null : user.getPasswordHash();

        // Always runs, always on a real digest, so every path costs the same time.
        boolean hashMatches =
                passwords.matches(password, storedHash == null ? TIMING_DECOY_HASH : storedHash);

        // Separate from the comparison on purpose: an account with no stored hash is refused
        // because it has no hash, not because the decoy failed to match. That ordering is what
        // makes the decoy's value a timing detail rather than a credential.
        boolean accountCanSignIn =
                user != null
                        && storedHash != null
                        && user.getDeactivatedAt() == null
                        && PORTAL_ROLES.contains(user.getRole());

        if (!accountCanSignIn || !hashMatches) {
            // Never logs the username: a failed-login log line with the attempted name in it turns
            // the application log into the enumeration oracle this method just avoided being.
            log.warn("portal sign-in rejected outcome=INVALID_CREDENTIALS");
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Wrong username or password.");
        }

        log.info("portal sign-in user={} outcome=OK role={}", user.getId(), user.getRole());
        return respond(user, user.getDisplayName(), false);
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
        // Refreshed every sign-in, not just at creation, so a name change on the Google side (or
        // an account created before this column existed) catches up without a second code path.
        existing.setDisplayName(identity.displayName());
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
        user.setDisplayName(identity.displayName());
        User saved = users.save(user);

        log.info("auth sign-up user={} outcome=CREATED role={}", saved.getId(), role);
        return respond(saved, identity.displayName(), true);
    }

    /**
     * A staff member changing their own password.
     *
     * <p>The caller is the JWT subject and nothing else — there is no user field to send, so an
     * admin cannot change someone else's password through this door and a staff member cannot
     * target an admin's. Resetting a forgotten password stays a manual database change
     * (docs/demo-runbook.md section 9), because a self-service reset needs a channel to prove
     * identity over and this product has neither verified email nor verified phone (ADR 0002).
     *
     * <p>The current password is required even though the caller already holds a session. A session
     * proves possession of a browser, not of the password: without this, a laptop left unlocked for
     * one minute is enough to lock its owner out of their own account for good.
     */
    @Transactional
    public void changePassword(UUID callerId, String currentPassword, String newPassword) {
        User user = requireCaller(callerId);

        if (user.getPasswordHash() == null || !PORTAL_ROLES.contains(user.getRole())) {
            // A donor or requester has no password to change — they authenticate through Google or
            // Telegram, and inventing one here would create a second way into their account.
            throw ApiException.unprocessable(
                    "NO_PASSWORD_LOGIN", "This account does not sign in with a password.");
        }
        if (!passwords.matches(currentPassword, user.getPasswordHash())) {
            log.warn("password change rejected user={} outcome=WRONG_CURRENT", callerId);
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Wrong current password.");
        }
        if (passwords.matches(newPassword, user.getPasswordHash())) {
            throw ApiException.unprocessable(
                    "PASSWORD_UNCHANGED",
                    "The new password must be different from the current one.");
        }

        user.setPasswordHash(passwords.encode(newPassword));
        // The session already issued stays valid until it expires — ADR 0007 has no server-side
        // revocation, so a password change cannot end other sessions. Worth knowing before anyone
        // treats this as a way to evict someone.
        log.info("password changed user={}", callerId);
    }

    /** Writes the caller's FCM token. The target is the JWT subject, never a body field. */
    @Transactional
    public void registerFcmToken(UUID userId, String fcmToken, String language) {
        User user = requireCaller(userId);
        // Idempotent by nature: the Firebase SDK rotates tokens on its own schedule and the client
        // re-posts whatever it currently holds, so the same value twice is a no-op, not an error.
        user.setFcmToken(fcmToken);
        // Absent means "unchanged", not "reset to the default" — a client that has not been updated
        // to send this must not silently push every donor back to Khmer. The value itself is
        // already constrained twice over: @Pattern on the DTO, and users_language_check in V1.
        if (language != null) {
            user.setLanguage(language);
        }
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
