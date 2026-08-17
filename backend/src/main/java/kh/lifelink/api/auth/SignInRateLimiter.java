package kh.lifelink.api.auth;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Per-IP fixed-window limit on sign-in (TM-AUTH-001 D1). {@code /auth/google} is unauthenticated
 * and does network I/O to Google on every call, which makes it the one endpoint where a flood costs
 * real resources.
 *
 * <p>In-memory and single-instance on purpose. A distributed limiter would be architecture for a
 * deployment that does not exist; when one does, this class is the seam to replace.
 *
 * <p>Fixed window rather than a token bucket: at this scale the difference is a burst at a window
 * boundary, and the simpler thing has less to get wrong.
 */
@Component
public class SignInRateLimiter {

    private record Window(Instant startedAt, AtomicInteger count) {}

    private final Map<String, Window> windows = new ConcurrentHashMap<>();
    private final int maxAttempts;
    private final Duration window;

    SignInRateLimiter(
            @Value("${lifelink.auth.rate-limit.max-attempts}") int maxAttempts,
            @Value("${lifelink.auth.rate-limit.window}") Duration window) {
        this.maxAttempts = maxAttempts;
        this.window = window;
    }

    /**
     * @return true when this caller is within its allowance
     */
    public boolean tryAcquire(String clientIp) {
        Instant now = Instant.now();
        Window current =
                windows.compute(
                        clientIp,
                        (ip, existing) ->
                                existing == null || existing.startedAt().plus(window).isBefore(now)
                                        ? new Window(now, new AtomicInteger(0))
                                        : existing);
        return current.count().incrementAndGet() <= maxAttempts;
    }

    /**
     * Drops windows that have expired. Without this the map grows by one entry per distinct client
     * IP and never shrinks — a slow leak that only shows up in a long-running process.
     */
    @org.springframework.scheduling.annotation.Scheduled(fixedDelay = 600_000)
    void evictExpired() {
        Instant cutoff = Instant.now().minus(window);
        windows.entrySet().removeIf(entry -> entry.getValue().startedAt().isBefore(cutoff));
    }
}
