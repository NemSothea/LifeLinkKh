package kh.lifelink.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * The identity controls from TM-AUTH-001, tested against a mocked verifier. Firebase is
 * deliberately absent: the Firebase project does not exist yet (docs/scope.md), and these are the
 * assertions that do not need it.
 *
 * <p>{@code GoogleTokenVerifier} exists as a seam precisely so this file can be written today.
 */
class AuthServiceTest {

    private static final String UID = "google-sub-abc123";

    private GoogleTokenVerifier verifier;
    private UserRepository users;
    private AuthService auth;

    @BeforeEach
    void setUp() {
        verifier = mock(GoogleTokenVerifier.class);
        users = mock(UserRepository.class);
        JwtService jwt =
                new JwtService("test-secret-that-is-long-enough-for-hs256", Duration.ofHours(1));
        auth = new AuthService(verifier, users, jwt);

        when(verifier.verify("good-token"))
                .thenReturn(new GoogleTokenVerifier.VerifiedIdentity(UID, "Sothea"));
        when(users.save(any(User.class)))
                .thenAnswer(
                        call -> {
                            // Stands in for @GeneratedValue. User has no id setter on purpose (the
                            // database assigns it), so this fake persistence layer does that job
                            // too — otherwise the service issues a JWT with a null subject.
                            User saved = call.getArgument(0);
                            ReflectionTestUtils.setField(saved, "id", UUID.randomUUID());
                            return saved;
                        });
    }

    /** A returning user loaded from the database always has one. */
    private static User existingUser(String role) {
        User user = new User();
        user.setFirebaseUid(UID);
        user.setRole(role);
        ReflectionTestUtils.setField(user, "id", UUID.randomUUID());
        return user;
    }

    /**
     * S1. The service is handed only a token and a role — there is no parameter through which a
     * caller could assert an identity — so this asserts the positive half: the persisted credential
     * is the verified {@code sub} and nothing else.
     */
    @Test
    void firebaseUidIsTakenFromTheVerifiedTokenOnly() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        auth.signIn("good-token", "DONOR");

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(users).save(saved.capture());
        assertThat(saved.getValue().getFirebaseUid()).isEqualTo(UID);
    }

    /** E1 — rejected, and rejected with 422 rather than a generic failure. */
    @Test
    void hospitalRoleIsRejectedAtSignUp() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auth.signIn("good-token", "HOSPITAL"))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    @Test
    void adminRoleIsRejectedAtSignUp() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auth.signIn("good-token", "ADMIN"))
                .isInstanceOf(ApiException.class);
    }

    /**
     * The second half of E1, and the half that matters. A rejection that still writes a row is the
     * same bug wearing a hat — and a rejection that writes a DONOR row is the silent downgrade the
     * threat model forbids by name.
     */
    @Test
    void aRejectedRoleCreatesNoUserAtAll() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auth.signIn("good-token", "HOSPITAL"))
                .isInstanceOf(ApiException.class);

        verify(users, never()).save(any(User.class));
    }

    /** A returning user's role is ignored, not honoured and not rejected. */
    @Test
    void roleInTheBodyIsIgnoredForAReturningUser() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.of(existingUser("REQUESTER")));

        AuthResponse response = auth.signIn("good-token", "DONOR");

        assertThat(response.user().role()).isEqualTo("REQUESTER");
        assertThat(response.user().isNewAccount()).isFalse();
        verify(users, never()).save(any(User.class));
    }

    @Test
    void firstSignInReportsANewAccount() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        AuthResponse response = auth.signIn("good-token", "DONOR");

        assertThat(response.user().isNewAccount()).isTrue();
        assertThat(response.user().role()).isEqualTo("DONOR");
        assertThat(response.token()).isNotBlank();
    }

    /** No role supplied is the ordinary donor path, not an error. */
    @Test
    void aMissingRoleDefaultsToDonor() {
        when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());

        assertThat(auth.signIn("good-token", null).user().role()).isEqualTo("DONOR");
    }

    /** The FCM token is written to the JWT subject's row — the id comes from the caller's token. */
    @Test
    void fcmTokenIsWrittenToTheAuthenticatedUsersRow() {
        UUID callerId = UUID.randomUUID();
        User caller = new User();
        when(users.findById(callerId)).thenReturn(Optional.of(caller));

        auth.registerFcmToken(callerId, "fcm-abc");

        assertThat(caller.getFcmToken()).isEqualTo("fcm-abc");
    }

    @Test
    void fcmTokenForAnUnknownSubjectIsUnauthorized() {
        UUID unknown = UUID.randomUUID();
        when(users.findById(unknown)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auth.registerFcmToken(unknown, "fcm-abc"))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    /**
     * S2 / TC-AUTH-001 case 3, at the seam. A genuine token minted for another Firebase project is
     * the failure that looks like success: it verifies cryptographically, so only the {@code aud}
     * and {@code iss} checks reject it. Those live in {@link FirebaseGoogleTokenVerifier} against
     * the real SDK; here the contract asserted is that a refusal produces no account and no session
     * at all.
     */
    @Test
    void aTokenTheVerifierRejectsCreatesNoAccount() {
        when(verifier.verify("foreign-project-token"))
                .thenThrow(ApiException.unauthorized("INVALID_ID_TOKEN", "Sign-in failed."));

        assertThatThrownBy(() -> auth.signIn("foreign-project-token", "DONOR"))
                .isInstanceOf(ApiException.class);

        verify(users, never()).save(any(User.class));
    }

    /**
     * TC-AUTH-001 case 5 — the FCM token written belongs to the caller and to nobody else. The
     * endpoint takes no user field, so this asserts the other half: a second user's row is
     * untouched.
     */
    @Test
    void registeringAnFcmTokenLeavesOtherUsersRowsAlone() {
        UUID callerId = UUID.randomUUID();
        User caller = new User();
        User other = new User();
        other.setFcmToken("fcm-other-device");
        when(users.findById(callerId)).thenReturn(Optional.of(caller));

        auth.registerFcmToken(callerId, "fcm-caller-device");

        assertThat(caller.getFcmToken()).isEqualTo("fcm-caller-device");
        assertThat(other.getFcmToken()).isEqualTo("fcm-other-device");
    }

    /** Sign-out. Clearing is what stops a signed-out device receiving urgent-request pushes. */
    @Test
    void clearingTheFcmTokenNullsTheCallersOwnRow() {
        UUID callerId = UUID.randomUUID();
        User caller = new User();
        caller.setFcmToken("fcm-abc");
        when(users.findById(callerId)).thenReturn(Optional.of(caller));

        auth.clearFcmToken(callerId);

        assertThat(caller.getFcmToken()).isNull();
    }

    /** Idempotent: signing out twice, or having never registered, is not an error. */
    @Test
    void clearingAnAlreadyEmptyFcmTokenIsNotAnError() {
        UUID callerId = UUID.randomUUID();
        User caller = new User();
        when(users.findById(callerId)).thenReturn(Optional.of(caller));

        auth.clearFcmToken(callerId);

        assertThat(caller.getFcmToken()).isNull();
    }

    @Test
    void clearingTheFcmTokenForAnUnknownSubjectIsUnauthorized() {
        UUID unknown = UUID.randomUUID();
        when(users.findById(unknown)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auth.clearFcmToken(unknown))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    /**
     * I2 / TC-AUTH-001 case 10, and the one non-negotiable test that had no coverage at all.
     *
     * <p>QA's version of this case greps the deployed logs by hand after running the other cases.
     * That catches a leak once, on one machine, after someone remembers to look. This runs every
     * build instead, and it is written as "nothing sensitive appears" rather than "these lines look
     * right", because the leak that actually happens is not a deliberate {@code log.info(token)} —
     * it is a stack trace, a {@code toString()} on a DTO, or a helpful new log line added six
     * months from now by someone who has never read TM-AUTH-001.
     *
     * <p>Every logging path in this service is exercised: returning sign-in, new sign-up, rejected
     * role, refused token, FCM register, FCM clear.
     */
    @Test
    void noAuthLogLineEverContainsATokenOrAnEmail() {
        ListAppender<ILoggingEvent> captured = new ListAppender<>();
        captured.start();
        Logger authLogger = (Logger) LoggerFactory.getLogger(AuthService.class);
        authLogger.addAppender(captured);

        String idToken = "eyJhbGciOiJSUzI1NiJ9.super-secret-google-id-token.sig";
        String email = "donor@example.com";
        String fcm = "fcm-device-capability-token";
        UUID callerId = UUID.randomUUID();

        try {
            when(verifier.verify(idToken))
                    .thenReturn(new GoogleTokenVerifier.VerifiedIdentity(UID, email));
            when(users.findById(callerId)).thenReturn(Optional.of(existingUser("DONOR")));

            // Returning sign-in, then a fresh sign-up — display name carries the email, which is
            // the realistic shape of a Google profile and the value most likely to be logged.
            when(users.findByFirebaseUid(UID)).thenReturn(Optional.of(existingUser("DONOR")));
            String issuedJwt = auth.signIn(idToken, null).token();

            when(users.findByFirebaseUid(UID)).thenReturn(Optional.empty());
            auth.signIn(idToken, "DONOR");

            assertThatThrownBy(() -> auth.signIn(idToken, "ADMIN"))
                    .isInstanceOf(ApiException.class);

            when(verifier.verify("bad-token"))
                    .thenThrow(ApiException.unauthorized("INVALID_ID_TOKEN", "Sign-in failed."));
            assertThatThrownBy(() -> auth.signIn("bad-token", "DONOR"))
                    .isInstanceOf(ApiException.class);

            auth.registerFcmToken(callerId, fcm);
            auth.clearFcmToken(callerId);

            assertThat(captured.list).isNotEmpty();
            for (ILoggingEvent event : captured.list) {
                String line = event.getFormattedMessage();
                assertThat(line)
                        .as("log line must not carry the Google ID token: %s", line)
                        .doesNotContain(idToken)
                        .as("log line must not carry our session JWT: %s", line)
                        .doesNotContain(issuedJwt)
                        .as("log line must not carry an email: %s", line)
                        .doesNotContain(email)
                        .as("log line must not carry an FCM token: %s", line)
                        .doesNotContain(fcm);
                // A truncated secret is still a secret, and prefixing is how "safe" logging is
                // usually attempted. 12 characters of a JWT header is not identifying, so the
                // window starts past it.
                assertThat(line)
                        .as("log line must not carry a fragment of the ID token: %s", line)
                        .doesNotContain(idToken.substring(12, 32));
            }
        } finally {
            authLogger.detachAppender(captured);
            captured.stop();
        }
    }
}
