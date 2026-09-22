package kh.lifelink.api.match;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.match.dto.MatchResponse;
import kh.lifelink.api.match.dto.RespondRequest;
import kh.lifelink.api.match.dto.RespondResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** The donor's inbox and the accept/decline action (FR-REQUEST-002). */
@RestController
@RequestMapping("/matches")
public class MatchController {

    private final MatchService matches;

    MatchController(MatchService matches) {
        this.matches = matches;
    }

    @GetMapping("/me")
    List<MatchResponse> listMine(@AuthenticationPrincipal UUID userId) {
        return matches.listMine(userId);
    }

    /**
     * {@code Idempotency-Key} is optional and sent only by a client replaying a write it queued
     * offline. Absent, this behaves exactly as before; present and matching an answer already
     * stored, the stored answer comes back instead of 409. See docs/mobile/local-db-and-sync.md.
     */
    @PostMapping("/{id}/respond")
    RespondResponse respond(
            @AuthenticationPrincipal UUID userId,
            @PathVariable("id") UUID id,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody RespondRequest body) {
        return matches.respond(userId, id, body, idempotencyKey);
    }
}
