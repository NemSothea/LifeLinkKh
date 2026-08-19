package kh.lifelink.api.request;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.request.dto.BloodRequestDetailResponse;
import kh.lifelink.api.request.dto.BloodRequestResponse;
import kh.lifelink.api.request.dto.RequestCreateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * <strong>Any authenticated user may create a request</strong> — deliberately not restricted to the
 * REQUESTER role. A donor whose relative needs blood is the most likely requester in the pilot, and
 * forcing them to hold a second account before posting an emergency is a failure mode with a body
 * count. The role split exists to stop self-assignment of HOSPITAL and ADMIN (TM-AUTH-001 E1), not
 * to gate this.
 */
@RestController
@RequestMapping("/requests")
public class RequestController {

    private final RequestService requests;

    RequestController(RequestService requests) {
        this.requests = requests;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    BloodRequestResponse create(
            @AuthenticationPrincipal UUID userId, @Valid @RequestBody RequestCreateRequest body) {
        return requests.create(userId, body);
    }

    @GetMapping("/me")
    List<BloodRequestResponse> listMine(@AuthenticationPrincipal UUID userId) {
        return requests.listMine(userId);
    }

    @GetMapping("/{id}")
    BloodRequestDetailResponse read(
            @AuthenticationPrincipal UUID userId, @PathVariable("id") UUID id) {
        return requests.read(userId, id);
    }

    @PostMapping("/{id}/cancel")
    BloodRequestResponse cancel(@AuthenticationPrincipal UUID userId, @PathVariable("id") UUID id) {
        return requests.cancel(userId, id);
    }
}
