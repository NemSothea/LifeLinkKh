package kh.lifelink.api.portal;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.portal.dto.ConfirmDonationRequest;
import kh.lifelink.api.portal.dto.ConfirmDonationResponse;
import kh.lifelink.api.portal.dto.PortalRequestResponse;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The hospital portal's one page (FR-PORTAL-001, trimmed by DEC-004). {@code SecurityConfig}
 * restricts every {@code /portal/**} path to {@code HOSPITAL} or {@code ADMIN} — a {@code DONOR}
 * or {@code REQUESTER} JWT reaching here gets a 403 before this class ever runs.
 */
@RestController
@RequestMapping("/portal/requests")
public class PortalController {

    private final PortalService portal;

    PortalController(PortalService portal) {
        this.portal = portal;
    }

    @GetMapping
    List<PortalRequestResponse> list(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "OPEN") String status) {
        return portal.listRequests(userId, status);
    }

    @PostMapping("/{id}/confirm-donation")
    @ResponseStatus(HttpStatus.CREATED)
    ConfirmDonationResponse confirmDonation(
            @AuthenticationPrincipal UUID userId,
            @PathVariable("id") UUID requestId,
            @Valid @RequestBody ConfirmDonationRequest body) {
        return portal.confirmDonation(userId, requestId, body);
    }
}
