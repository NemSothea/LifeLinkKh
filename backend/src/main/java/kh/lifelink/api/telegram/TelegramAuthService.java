package kh.lifelink.api.telegram;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Verify (via a Telegram-delivered code, not a token), find-or-create, issue — the Telegram
 * equivalent of {@code AuthService}, TM-AUTH-002.
 *
 * <p>{@code chatId} is this provider's credential, exactly as {@code sub} is Google's: it arrives
 * on this class only through {@link #recordOtpSent}, called by the controller only after the
 * webhook's secret-token header has already verified as genuinely from Telegram (S1/S2). Nothing
 * here accepts a {@code chatId} from the app.
 */
@Service
public class TelegramAuthService {

    private static final Logger log = LoggerFactory.getLogger(TelegramAuthService.class);

    private static final List<String> SELF_SERVICE_ROLES = List.of("DONOR", "REQUESTER");
    private static final int OTP_DIGITS = 6;
    private static final int MAX_ATTEMPTS = 6;
    private static final Duration OTP_TTL = Duration.ofMinutes(5);
    private static final Duration RESEND_COOLDOWN = Duration.ofSeconds(30);

    private final TelegramAuthChallengeRepository challenges;
    private final TelegramBotClient bot;
    private final TelegramConfig config;
    private final UserRepository users;
    private final JwtService jwt;
    private final SecureRandom random = new SecureRandom();

    TelegramAuthService(
            TelegramAuthChallengeRepository challenges,
            TelegramBotClient bot,
            TelegramConfig config,
            UserRepository users,
            JwtService jwt) {
        this.challenges = challenges;
        this.bot = bot;
        this.config = config;
        this.users = users;
        this.jwt = jwt;
    }

    /** {@code POST /auth/telegram/start}. */
    @Transactional
    public TelegramSession start(String requestedRole) {
        config.requireConfigured();
        String role = requestedRole == null ? "DONOR" : requestedRole;
        if (!SELF_SERVICE_ROLES.contains(role)) {
            log.warn("telegram sign-up rejected outcome=ROLE_NOT_SELF_SERVICE role={}", role);
            throw ApiException.unprocessable(
                    "ROLE_NOT_SELF_SERVICE", "That role cannot be chosen at sign-up.");
        }

        TelegramAuthChallenge challenge = new TelegramAuthChallenge();
        challenge.setSessionToken(randomToken());
        challenge.setRole(role);
        challenge = challenges.save(challenge);

        String deepLink = "https://t.me/" + config.botUsername() + "?start=" + challenge.getSessionToken();
        return new TelegramSession(challenge.getSessionToken(), deepLink);
    }

    /**
     * Called by the controller once — and only once — the webhook's secret-token header has
     * verified. {@code chatId} is trusted from here on for this challenge.
     *
     * <p>Silently a no-op for an unknown, already-consumed session token, or one still inside its
     * resend cooldown — a webhook caller (Telegram, or whoever forged the header) learns nothing
     * about which case it was (TM-AUTH-002 S1 residual: the header check is the real gate; this is
     * just not making a bad guess more informative than it has to be).
     */
    @Transactional
    public void recordOtpSent(String sessionToken, long chatId, String displayName) {
        config.requireConfigured();
        challenges
                .findBySessionToken(sessionToken)
                .filter(c -> c.getConsumedAt() == null)
                .filter(
                        c ->
                                c.getOtpSentAt() == null
                                        || c.getOtpSentAt().plus(RESEND_COOLDOWN).isBefore(OffsetDateTime.now()))
                .ifPresent(
                        challenge -> {
                            String code = randomOtp();
                            challenge.setChatId(chatId);
                            challenge.setOtpHash(sha256Hex(code));
                            challenge.setDisplayName(displayName);
                            challenge.setOtpSentAt(OffsetDateTime.now());
                            challenge.setExpiresAt(OffsetDateTime.now().plus(OTP_TTL));
                            // A fresh code invalidates whatever guesses were spent on the last one.
                            challenge.resetAttemptCount();
                            bot.sendMessage(
                                    chatId,
                                    "Your LifeLink code is "
                                            + code
                                            + ". It expires in "
                                            + OTP_TTL.toMinutes()
                                            + " minutes.");
                        });
    }

    /** {@code POST /auth/telegram/verify}. */
    @Transactional
    public AuthResponse verify(String sessionToken, String code) {
        config.requireConfigured();
        TelegramAuthChallenge challenge =
                challenges
                        .findBySessionToken(sessionToken)
                        .filter(c -> c.getConsumedAt() == null)
                        .filter(c -> c.getOtpHash() != null)
                        .orElseThrow(TelegramAuthService::invalidCode);

        if (challenge.getExpiresAt() == null || challenge.getExpiresAt().isBefore(OffsetDateTime.now())) {
            throw invalidCode();
        }
        if (challenge.getAttemptCount() >= MAX_ATTEMPTS) {
            throw ApiException.unprocessable(
                    "TOO_MANY_ATTEMPTS", "Too many wrong codes. Request a new one.");
        }
        if (!MessageDigest.isEqual(
                sha256Hex(code).getBytes(StandardCharsets.UTF_8),
                challenge.getOtpHash().getBytes(StandardCharsets.UTF_8))) {
            challenge.incrementAttemptCount();
            throw invalidCode();
        }

        challenge.setConsumedAt(OffsetDateTime.now());
        long chatId = challenge.getChatId();
        boolean isNewAccount = users.findByTelegramChatId(chatId).isEmpty();
        User user =
                users.findByTelegramChatId(chatId)
                        .orElseGet(
                                () -> {
                                    User created = new User();
                                    created.setTelegramChatId(chatId);
                                    created.setRole(challenge.getRole());
                                    return users.save(created);
                                });
        // Refreshed every sign-in, same as Google's displayName handling — catches a name change
        // and backfills an account created before this field existed.
        user.setDisplayName(challenge.getDisplayName());

        log.info(
                "telegram sign-in user={} outcome={}",
                user.getId(),
                isNewAccount ? "CREATED" : "RETURNING");

        return new AuthResponse(
                jwt.issue(user.getId(), user.getRole()),
                new AuthResponse.AuthenticatedUser(
                        user.getId(), user.getRole(), user.getDisplayName(), isNewAccount));
    }

    private static ApiException invalidCode() {
        return ApiException.unauthorized("TELEGRAM_CODE_INVALID", "That code is not valid.");
    }

    private String randomToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String randomOtp() {
        int max = (int) Math.pow(10, OTP_DIGITS);
        int value = random.nextInt(max);
        return String.format(Locale.ROOT, "%0" + OTP_DIGITS + "d", value);
    }

    private static String sha256Hex(String value) {
        try {
            byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException ex) {
            // SHA-256 is mandated by every JDK security provider; this cannot happen at runtime.
            throw new IllegalStateException(ex);
        }
    }

    public record TelegramSession(String sessionToken, String deepLink) {}
}
