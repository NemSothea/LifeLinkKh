package kh.lifelink.api.telegram;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.telegram.dto.TelegramStartRequest;
import kh.lifelink.api.telegram.dto.TelegramStartResponse;
import kh.lifelink.api.telegram.dto.TelegramVerifyRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * TM-AUTH-002. Three unauthenticated endpoints, same exemption shape {@code SecurityConfig} already
 * carves out for {@code POST /auth/google} — {@code start} and {@code verify} are called by the app
 * before a session exists; {@code webhook} is called by Telegram, never by the app at all, and is
 * gated on the secret-token header instead of a JWT.
 */
@RestController
@RequestMapping("/auth/telegram")
public class TelegramAuthController {

    private static final String SECRET_HEADER = "X-Telegram-Bot-Api-Secret-Token";
    private static final String START_COMMAND = "/start ";

    private final TelegramAuthService telegram;
    private final TelegramConfig config;
    private final TelegramRateLimiter rateLimiter;

    TelegramAuthController(
            TelegramAuthService telegram, TelegramConfig config, TelegramRateLimiter rateLimiter) {
        this.telegram = telegram;
        this.config = config;
        this.rateLimiter = rateLimiter;
    }

    @PostMapping("/start")
    TelegramStartResponse start(
            @RequestBody(required = false) TelegramStartRequest body, HttpServletRequest request) {
        if (!rateLimiter.tryAcquireStart(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many attempts.");
        }
        TelegramAuthService.TelegramSession session = telegram.start(body == null ? null : body.role());
        return new TelegramStartResponse(session.sessionToken(), session.deepLink());
    }

    /**
     * Telegram retries a webhook that doesn't answer quickly, so this always returns 200 once the
     * secret-token header checks out — an unrecognised or already-consumed session token is a
     * silent no-op inside the service, not a reason to make Telegram retry forever.
     */
    @PostMapping("/webhook")
    ResponseEntity<Void> webhook(
            @RequestHeader(value = SECRET_HEADER, required = false) String secretToken,
            @RequestBody(required = false) TelegramUpdate update) {
        if (!config.verifyWebhookSecret(secretToken)) {
            return ResponseEntity.status(401).build();
        }
        if (update != null && update.message() != null && update.message().text() != null) {
            String text = update.message().text();
            if (text.startsWith(START_COMMAND)) {
                String sessionToken = text.substring(START_COMMAND.length()).trim();
                String firstName =
                        update.message().from() == null ? null : update.message().from().firstName();
                telegram.recordOtpSent(sessionToken, update.message().chat().id(), firstName);
            }
        }
        return ResponseEntity.ok().build();
    }

    @PostMapping("/verify")
    AuthResponse verify(@Valid @RequestBody TelegramVerifyRequest body, HttpServletRequest request) {
        if (!rateLimiter.tryAcquireVerify(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many attempts.");
        }
        return telegram.verify(body.sessionToken(), body.code());
    }
}
