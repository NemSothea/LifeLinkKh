package kh.lifelink.api.telegram;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * TM-AUTH-002's controls, tested against a faked {@link TelegramBotClient} — the seam exists
 * precisely so this can be written before a real bot does.
 */
class TelegramAuthServiceTest {

    private static final long CHAT_ID = 987654321L;

    private TelegramAuthChallengeRepository challenges;
    private TelegramBotClient bot;
    private UserRepository users;
    private TelegramAuthService service;

    @BeforeEach
    void setUp() {
        challenges = mock(TelegramAuthChallengeRepository.class);
        bot = mock(TelegramBotClient.class);
        users = mock(UserRepository.class);
        TelegramConfig config =
                new TelegramConfig("test-bot-token", "test-webhook-secret", "TestBot");
        JwtService jwt = mock(JwtService.class);
        when(jwt.issue(any(UUID.class), anyString())).thenReturn("fake-jwt");
        service = new TelegramAuthService(challenges, bot, config, users, jwt);

        when(challenges.save(any(TelegramAuthChallenge.class)))
                .thenAnswer(call -> call.getArgument(0));
        when(users.save(any(User.class)))
                .thenAnswer(
                        call -> {
                            User saved = call.getArgument(0);
                            ReflectionTestUtils.setField(saved, "id", UUID.randomUUID());
                            return saved;
                        });
    }

    private TelegramAuthChallenge challengeSentAt(OffsetDateTime sentAt, String code) {
        TelegramAuthChallenge challenge = new TelegramAuthChallenge();
        ReflectionTestUtils.setField(challenge, "sessionToken", "tok-1");
        ReflectionTestUtils.setField(challenge, "role", "DONOR");
        challenge.setChatId(CHAT_ID);
        challenge.setOtpHash(sha256(code));
        challenge.setOtpSentAt(sentAt);
        challenge.setExpiresAt(sentAt.plusMinutes(5));
        return challenge;
    }

    private static String sha256(String value) {
        try {
            var digest =
                    java.security.MessageDigest.getInstance("SHA-256")
                            .digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @Test
    void start_rejects_a_non_self_service_role() {
        assertThatThrownBy(() -> service.start("ADMIN"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
                            assertThat(ex.getCode()).isEqualTo("ROLE_NOT_SELF_SERVICE");
                        });
    }

    @Test
    void start_defaults_to_donor_and_returns_a_deep_link_to_the_configured_bot() {
        var session = service.start(null);

        assertThat(session.deepLink())
                .isEqualTo("https://t.me/TestBot?start=" + session.sessionToken());
        assertThat(session.sessionToken()).isNotBlank();
    }

    @Test
    void everything_503s_when_telegram_is_not_configured() {
        TelegramConfig unconfigured = new TelegramConfig("", "", "");
        TelegramAuthService unavailable =
                new TelegramAuthService(
                        challenges, bot, unconfigured, users, mock(JwtService.class));

        assertThatThrownBy(() -> unavailable.start("DONOR"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                            assertThat(ex.getCode()).isEqualTo("TELEGRAM_PROVIDER_UNCONFIGURED");
                        });
    }

    @Test
    void recordOtpSent_is_a_silent_no_op_for_an_unknown_session_token() {
        when(challenges.findBySessionToken("nope")).thenReturn(Optional.empty());

        service.recordOtpSent("nope", CHAT_ID, "Sok Dara");

        verify(bot, never()).sendMessage(anyLong(), anyString());
    }

    @Test
    void recordOtpSent_sends_a_code_and_stores_its_hash_not_the_code() {
        TelegramAuthChallenge fresh = new TelegramAuthChallenge();
        ReflectionTestUtils.setField(fresh, "sessionToken", "tok-1");
        ReflectionTestUtils.setField(fresh, "role", "DONOR");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(fresh));

        service.recordOtpSent("tok-1", CHAT_ID, "Sok Dara");

        verify(bot).sendMessage(eq(CHAT_ID), anyString());
        assertThat(fresh.getChatId()).isEqualTo(CHAT_ID);
        assertThat(fresh.getDisplayName()).isEqualTo("Sok Dara");
        assertThat(fresh.getOtpHash()).isNotBlank();
        assertThat(fresh.getExpiresAt()).isAfter(OffsetDateTime.now());
    }

    @Test
    void recordOtpSent_respects_the_resend_cooldown() {
        TelegramAuthChallenge justSent = challengeSentAt(OffsetDateTime.now(), "111111");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(justSent));

        service.recordOtpSent("tok-1", CHAT_ID, "Sok Dara");

        verify(bot, never()).sendMessage(anyLong(), anyString());
    }

    @Test
    void recordOtpSent_resends_once_the_cooldown_has_passed() {
        TelegramAuthChallenge staleSend =
                challengeSentAt(OffsetDateTime.now().minusSeconds(31), "111111");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(staleSend));

        service.recordOtpSent("tok-1", CHAT_ID, "Sok Dara");

        verify(bot, times(1)).sendMessage(eq(CHAT_ID), anyString());
    }

    @Test
    void verify_rejects_the_wrong_code_and_counts_the_attempt() {
        TelegramAuthChallenge challenge = challengeSentAt(OffsetDateTime.now(), "111111");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(challenge));

        assertThatThrownBy(() -> service.verify("tok-1", "000000"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.UNAUTHORIZED);
                            assertThat(ex.getCode()).isEqualTo("TELEGRAM_CODE_INVALID");
                        });
        assertThat(challenge.getAttemptCount()).isEqualTo((short) 1);
    }

    @Test
    void verify_rejects_an_expired_challenge() {
        TelegramAuthChallenge expired =
                challengeSentAt(OffsetDateTime.now().minusMinutes(10), "111111");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(expired));

        assertThatThrownBy(() -> service.verify("tok-1", "111111"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("TELEGRAM_CODE_INVALID"));
    }

    @Test
    void verify_locks_out_after_six_wrong_attempts() {
        TelegramAuthChallenge challenge = challengeSentAt(OffsetDateTime.now(), "111111");
        for (int i = 0; i < 6; i++) {
            challenge.incrementAttemptCount();
        }
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(challenge));

        assertThatThrownBy(() -> service.verify("tok-1", "111111"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> {
                            assertThat(ex.getStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
                            assertThat(ex.getCode()).isEqualTo("TOO_MANY_ATTEMPTS");
                        });
    }

    @Test
    void verify_creates_a_new_account_with_the_challenges_role_and_display_name() {
        TelegramAuthChallenge challenge = challengeSentAt(OffsetDateTime.now(), "111111");
        ReflectionTestUtils.setField(challenge, "displayName", "Sok Dara");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(challenge));
        when(users.findByTelegramChatId(CHAT_ID)).thenReturn(Optional.empty());

        AuthResponse response = service.verify("tok-1", "111111");

        assertThat(response.user().isNewAccount()).isTrue();
        assertThat(response.user().role()).isEqualTo("DONOR");
        assertThat(response.user().displayName()).isEqualTo("Sok Dara");
        assertThat(response.token()).isNotBlank();
        assertThat(challenge.getConsumedAt()).isNotNull();
    }

    @Test
    void verify_ignores_the_challenge_role_for_a_returning_chat_id() {
        User existing = new User();
        ReflectionTestUtils.setField(existing, "id", UUID.randomUUID());
        existing.setTelegramChatId(CHAT_ID);
        existing.setRole("REQUESTER");

        TelegramAuthChallenge challenge = challengeSentAt(OffsetDateTime.now(), "111111");
        ReflectionTestUtils.setField(challenge, "role", "DONOR");
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(challenge));
        when(users.findByTelegramChatId(CHAT_ID)).thenReturn(Optional.of(existing));

        AuthResponse response = service.verify("tok-1", "111111");

        assertThat(response.user().isNewAccount()).isFalse();
        assertThat(response.user().role()).isEqualTo("REQUESTER");
    }

    @Test
    void verify_refuses_to_reuse_an_already_consumed_challenge() {
        TelegramAuthChallenge challenge = challengeSentAt(OffsetDateTime.now(), "111111");
        challenge.setConsumedAt(OffsetDateTime.now());
        when(challenges.findBySessionToken("tok-1")).thenReturn(Optional.of(challenge));

        assertThatThrownBy(() -> service.verify("tok-1", "111111"))
                .isInstanceOfSatisfying(
                        ApiException.class,
                        ex -> assertThat(ex.getCode()).isEqualTo("TELEGRAM_CODE_INVALID"));
    }
}
