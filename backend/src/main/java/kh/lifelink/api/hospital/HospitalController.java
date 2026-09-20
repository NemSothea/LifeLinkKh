package kh.lifelink.api.hospital;

import java.util.List;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The hospital list behind the urgent-request form's dropdown.
 *
 * <p>Reference data with the same constraint as {@code GET /districts}: {@code hospital_id} on a
 * blood request is a foreign key, so a client-bundled list goes stale into a 422 that the person
 * filling the form cannot act on. Reading it from the server keeps the dropdown and the constraint
 * in step.
 *
 * <p>Authenticated, like everything that is not one of the three exemptions in {@code
 * SecurityConfig}. The names are public, but the deny-by-default chain is worth more than one round
 * trip.
 *
 * <p>The district join and the ordering live in {@link HospitalService}.
 */
@RestController
@RequestMapping("/hospitals")
public class HospitalController {

    private final HospitalService service;

    HospitalController(HospitalService service) {
        this.service = service;
    }

    @GetMapping
    List<HospitalResponse> list() {
        return service.list();
    }
}
