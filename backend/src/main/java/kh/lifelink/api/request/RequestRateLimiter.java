package kh.lifelink.api.request;

import java.time.Duration;
import java.util.UUID;
import kh.lifelink.api.common.ratelimit.FixedWindowLimiter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Per-user limit on request creation.
 *
 * <p>Keyed by user, not by IP: the endpoint is authenticated, so the account is the real actor and
 * an IP is a proxy that a phone changes every time it moves between wifi and mobile data.
 *
 * <p>This is ADR 0008's reasoning applied to a second axis. The cap of 25 bounds how far one
 * request reaches; this bounds how many requests one person can make. Unthrottled, a single account
 * is a spam cannon aimed at exactly the population whose attention this product depends on — and
 * unlike sign-in, the cost of abuse here lands on donors rather than on the server.
 */
@Component
public class RequestRateLimiter {

    private final FixedWindowLimiter limiter;

    RequestRateLimiter(
            @Value("${lifelink.request.rate-limit.max-attempts}") int maxAttempts,
            @Value("${lifelink.request.rate-limit.window}") Duration window) {
        this.limiter = new FixedWindowLimiter(maxAttempts, window);
    }

    public boolean tryAcquire(UUID userId) {
        return limiter.tryAcquire(userId.toString());
    }

    @org.springframework.scheduling.annotation.Scheduled(fixedDelay = 600_000)
    void evictExpired() {
        limiter.evictExpired();
    }
}
