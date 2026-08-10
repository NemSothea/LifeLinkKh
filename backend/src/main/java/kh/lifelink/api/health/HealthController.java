package kh.lifelink.api.health;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Unauthenticated liveness endpoint. Served at {@code GET /api/health} — the {@code /api} prefix
 * comes from {@code server.servlet.context-path}, so it is not repeated in the mapping.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
