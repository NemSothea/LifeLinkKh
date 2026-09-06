package kh.lifelink.api.board;

import java.time.Duration;
import kh.lifelink.api.common.ratelimit.FixedWindowLimiter;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Per-IP limit on the public board.
 *
 * <p>Its own limiter rather than {@code SignInRateLimiter}'s, because the two protect different
 * things and want different numbers: five sign-in attempts a minute is a brute-force ceiling, while
 * a ward screen left open refreshing every thirty seconds is normal traffic here. Sharing one
 * bucket would let a page refresh lock somebody out of signing in.
 */
@Component
public class PublicBoardRateLimiter {

    private final FixedWindowLimiter limiter = new FixedWindowLimiter(120, Duration.ofMinutes(1));

    public boolean tryAcquire(String clientIp) {
        return limiter.tryAcquire(clientIp);
    }

    @Scheduled(fixedDelay = 600_000)
    void evictExpired() {
        limiter.evictExpired();
    }
}
