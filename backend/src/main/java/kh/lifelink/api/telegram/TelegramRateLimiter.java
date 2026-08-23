package kh.lifelink.api.telegram;

import java.time.Duration;
import kh.lifelink.api.common.ratelimit.FixedWindowLimiter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Per-IP limits on {@code /auth/telegram/start} and {@code /auth/telegram/verify} (TM-AUTH-002
 * D1) — two separate {@link FixedWindowLimiter} instances, same reasoning {@code
 * SignInRateLimiter}'s own javadoc gives for never sharing one limiter across two different
 * allowances. {@code verify} additionally caps attempts per challenge row (TM-AUTH-002 S3),
 * independent of this — this limiter alone would not stop a flood from many different challenge
 * tokens against one IP.
 */
@Component
public class TelegramRateLimiter {

    private final FixedWindowLimiter start;
    private final FixedWindowLimiter verify;

    TelegramRateLimiter(
            @Value("${lifelink.telegram.rate-limit.start.max-attempts}") int startMaxAttempts,
            @Value("${lifelink.telegram.rate-limit.start.window}") Duration startWindow,
            @Value("${lifelink.telegram.rate-limit.verify.max-attempts}") int verifyMaxAttempts,
            @Value("${lifelink.telegram.rate-limit.verify.window}") Duration verifyWindow) {
        this.start = new FixedWindowLimiter(startMaxAttempts, startWindow);
        this.verify = new FixedWindowLimiter(verifyMaxAttempts, verifyWindow);
    }

    public boolean tryAcquireStart(String clientIp) {
        return start.tryAcquire(clientIp);
    }

    public boolean tryAcquireVerify(String clientIp) {
        return verify.tryAcquire(clientIp);
    }

    @org.springframework.scheduling.annotation.Scheduled(fixedDelay = 600_000)
    void evictExpired() {
        start.evictExpired();
        verify.evictExpired();
    }
}
