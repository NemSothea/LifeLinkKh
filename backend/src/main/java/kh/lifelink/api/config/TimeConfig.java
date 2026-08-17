package kh.lifelink.api.config;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * A {@link Clock} bean, so the 56-day cooldown is testable at its boundary without waiting for a
 * calendar. Nothing in the domain calls {@code LocalDate.now()} directly.
 *
 * <p>Scheduling is enabled here for the sign-in rate limiter's eviction sweep — its only current
 * use.
 */
@Configuration
@EnableScheduling
public class TimeConfig {

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }
}
