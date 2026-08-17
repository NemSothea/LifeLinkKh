package kh.lifelink.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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

    /** S2, at the seam. A token the verifier refuses never reaches the user table. */
    @Test
    void aTokenTheVerifierRejectsCreatesNoAccount() {
        when(verifier.verify("foreign-project-token"))
                .thenThrow(ApiException.unauthorized("INVALID_ID_TOKEN", "Sign-in failed."));

        assertThatThrownBy(() -> auth.signIn("foreign-project-token", "DONOR"))
                .isInstanceOf(ApiException.class);

        verify(users, never()).save(any(User.class));
    }
}
