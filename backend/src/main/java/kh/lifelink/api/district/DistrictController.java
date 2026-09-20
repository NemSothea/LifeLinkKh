package kh.lifelink.api.district;

import java.util.List;
import kh.lifelink.api.district.dto.DistrictResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The district list behind the donor-registration dropdown (CR-MAPI-002).
 *
 * <p>Reference data, and the client cannot hold its own copy: {@code district_code} is a foreign
 * key, so a stale bundled list produces a 422 on save that the donor cannot act on. Reading it from
 * the server is what keeps the dropdown and the constraint in step.
 *
 * <p>Authenticated like everything else. Nothing here is secret — 14 public place names — but the
 * deny-by-default chain has exactly three exemptions and this is not one of them; adding a fourth
 * to save one round trip would trade a security property for nothing.
 *
 * <p>Ordering and mapping live in {@link DistrictService}: what the list means is a decision, and
 * decisions do not belong in the layer whose job is HTTP.
 */
@RestController
@RequestMapping("/districts")
public class DistrictController {

    private final DistrictService service;

    DistrictController(DistrictService service) {
        this.service = service;
    }

    @GetMapping
    List<DistrictResponse> list() {
        return service.list();
    }
}
