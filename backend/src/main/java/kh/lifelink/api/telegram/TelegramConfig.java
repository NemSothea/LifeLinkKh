package kh.lifelink.api.telegram;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import kh.lifelink.api.common.error.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Telegram bot configuration, same split as {@code FirebaseConfig}: the bot does not exist yet
 * (docs/scope.md-style external lead time — creating it is a `@BotFather` conversation, not code),
 * so rather than fail the whole API at startup, every {@code /auth/telegram/*} endpoint answers
 * **503 TELEGRAM_PROVIDER_UNCONFIGURED** until all three values are set.
 *
 * <p>All three empty by default, deliberately — unlike the JWT secret or the datasource
 * credentials, this is not something every environment must have to boot. A missing value here
 * degrades one feature; a missing JWT secret must not boot at all.
 */
@Component
public class TelegramConfig {

    private final String botToken;
    private final String webhookSecret;
    private final String botUsername;

    TelegramConfig(
            @Value("${lifelink.telegram.bot-token:}") String botToken,
            @Value("${lifelink.telegram.webhook-secret:}") String webhookSecret,
            @Value("${lifelink.telegram.bot-username:}") String botUsername) {
        this.botToken = botToken;
        this.webhookSecret = webhookSecret;
        this.botUsername = botUsername;
    }

    public boolean isAvailable() {
        return !botToken.isBlank() && !webhookSecret.isBlank() && !botUsername.isBlank();
    }

    public void requireConfigured() {
        if (!isAvailable()) {
            throw ApiException.providerUnavailable(
                    "TELEGRAM_PROVIDER_UNCONFIGURED", "Telegram sign-in is unavailable.");
        }
    }

    String botToken() {
        return botToken;
    }

    public String botUsername() {
        return botUsername;
    }

    /**
     * TM-AUTH-002 S1: the only thing distinguishing a real Telegram webhook call from anyone on
     * the internet POSTing to the same URL. Constant-time on purpose — same reasoning as the OTP
     * hash comparison (T1): a non-constant-time check leaks how much of the secret the caller got
     * right.
     */
    public boolean verifyWebhookSecret(String headerValue) {
        if (headerValue == null) {
            return false;
        }
        return MessageDigest.isEqual(
                webhookSecret.getBytes(StandardCharsets.UTF_8),
                headerValue.getBytes(StandardCharsets.UTF_8));
    }
}
