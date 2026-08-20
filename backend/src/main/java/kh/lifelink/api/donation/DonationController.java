package kh.lifelink.api.donation;

import java.util.List;
import java.util.UUID;
import kh.lifelink.api.donation.dto.DonationResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Reads the JWT subject's own donations only — no path parameter, no query filter, the same shape
 * as {@link kh.lifelink.api.donor.DonorController}.
 */
@RestController
@RequestMapping("/donations")
public class DonationController {

    private final DonationService donations;

    DonationController(DonationService donations) {
        this.donations = donations;
    }

    @GetMapping("/me")
    List<DonationResponse> mine(@AuthenticationPrincipal UUID userId) {
        return donations.listForUser(userId);
    }
}
