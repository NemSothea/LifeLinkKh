package kh.lifelink.api.common.ratelimit;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A fixed-window counter keyed by an opaque string — an IP for sign-in, a user id for request
 * creation.
 *
 * <p>In-memory and single-instance on purpose. A distributed limiter would be architecture for a
 * deployment that does not exist; when one does, this class is the seam to replace.
 *
 * <p>Fixed window rather than a token bucket: at this scale the difference is a burst at a window
 * boundary, and the simpler thing has less to get wrong.
 *
 * <p>Not a bean. Each limiter owns its own instance with its own numbers — sharing one would mean
 * sign-in attempts and blood requests competing for the same allowance.
 */
public final class FixedWindowLimiter {

    private record Window(Instant startedAt, AtomicInteger count) {}

    private final Map<String, Window> windows = new ConcurrentHashMap<>();
    private final int maxAttempts;
    private final Duration window;

    public FixedWindowLimiter(int maxAttempts, Duration window) {
        this.maxAttempts = maxAttempts;
        this.window = window;
    }

    /**
     * @return true when this key is within its allowance
     */
    public boolean tryAcquire(String key) {
        Instant now = Instant.now();
        Window current =
                windows.compute(
                        key,
                        (ignored, existing) ->
                                existing == null || existing.startedAt().plus(window).isBefore(now)
                                        ? new Window(now, new AtomicInteger(0))
                                        : existing);
        return current.count().incrementAndGet() <= maxAttempts;
    }

    /**
     * Drops windows that have expired. Without this the map grows by one entry per distinct key and
     * never shrinks — a slow leak that only shows up in a long-running process.
     */
    public void evictExpired() {
        Instant cutoff = Instant.now().minus(window);
        windows.entrySet().removeIf(entry -> entry.getValue().startedAt().isBefore(cutoff));
    }
}
