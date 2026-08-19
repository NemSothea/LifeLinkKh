package kh.lifelink.api.auth;

import java.time.Duration;
import kh.lifelink.api.common.ratelimit.FixedWindowLimiter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Per-IP limit on sign-in (TM-AUTH-001 D1). {@code /auth/google} is unauthenticated and does
 * network I/O to Google on every call, which makes it the one endpoint where a flood costs real
 * resources.
 *
 * <p>The window mechanics moved to {@link FixedWindowLimiter} at M4, when {@code POST /requests}
 * needed the same shape keyed by user instead of by IP. Behaviour here is unchanged.
 */
@Component
public class SignInRateLimiter {

    private final FixedWindowLimiter limiter;

    SignInRateLimiter(
            @Value("${lifelink.auth.rate-limit.max-attempts}") int maxAttempts,
            @Value("${lifelink.auth.rate-limit.window}") Duration window) {
        this.limiter = new FixedWindowLimiter(maxAttempts, window);
    }

    /**
     * @return true when this caller is within its allowance
     */
    public boolean tryAcquire(String clientIp) {
        return limiter.tryAcquire(clientIp);
    }

    @org.springframework.scheduling.annotation.Scheduled(fixedDelay = 600_000)
    void evictExpired() {
        limiter.evictExpired();
    }
}
