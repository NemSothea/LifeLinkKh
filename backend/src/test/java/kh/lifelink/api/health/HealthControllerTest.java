package kh.lifelink.api.health;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import kh.lifelink.api.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

/**
 * A web-slice test on purpose: it must pass in CI with no PostgreSQL running. Full-context boot,
 * Flyway, and schema validation are verified by {@code docker compose up}, not by the build.
 *
 * <p>{@code SecurityConfig} is imported explicitly — the slice does not pick it up, and without it
 * Spring Boot's default chain answers 401, so the test would prove nothing about our own config.
 */
@WebMvcTest(HealthController.class)
@Import(SecurityConfig.class)
class HealthControllerTest {

    @Autowired private MockMvc mockMvc;

    @Test
    void healthReturnsUpWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
