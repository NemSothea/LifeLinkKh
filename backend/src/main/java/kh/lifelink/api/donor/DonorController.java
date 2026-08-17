package kh.lifelink.api.donor;

import jakarta.validation.Valid;
import java.util.UUID;
import kh.lifelink.api.donor.dto.DonorProfileResponse;
import kh.lifelink.api.donor.dto.DonorProfileWriteRequest;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Both endpoints operate on the JWT subject's own row. No path parameter, no query filter, no
 * "admin can also" branch — the donor-reads-and-writes-only-their-own rule from the ASVS baseline
 * holds structurally, because there is no identifier here to tamper with.
 */
@RestController
@RequestMapping("/donors")
public class DonorController {

    private final DonorService donors;

    DonorController(DonorService donors) {
        this.donors = donors;
    }

    @GetMapping("/me")
    DonorProfileResponse read(@AuthenticationPrincipal UUID userId) {
        return donors.read(userId);
    }

    @PutMapping("/me")
    DonorProfileResponse save(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody DonorProfileWriteRequest body) {
        return donors.save(userId, body);
    }
}
