package kh.lifelink.api.hospital;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.district.dto.DistrictName;
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
 */
@RestController
@RequestMapping("/hospitals")
public class HospitalController {

    private final HospitalRepository hospitals;
    private final DistrictRepository districts;

    HospitalController(HospitalRepository hospitals, DistrictRepository districts) {
        this.hospitals = hospitals;
        this.districts = districts;
    }

    /**
     * Sorted by name. Unlike the district list this is Latin-script and short, so there is no
     * collation argument to have — but it is sorted server-side for the same reason: two clients
     * that sort differently show two different dropdowns for the same data.
     *
     * <p>Districts are read once into a map rather than per hospital. At five rows the difference
     * is nothing; the shape matters because this is the list endpoint that grows.
     */
    @GetMapping
    List<HospitalResponse> list() {
        Map<String, District> byCode =
                districts.findAll().stream()
                        .collect(
                                java.util.stream.Collectors.toMap(
                                        District::getCode, Function.identity()));

        return hospitals.findAll().stream()
                .map(
                        h -> {
                            District district =
                                    h.getDistrictCode() == null
                                            ? null
                                            : byCode.get(h.getDistrictCode());
                            return new HospitalResponse(
                                    h.getId(),
                                    h.getName(),
                                    district == null
                                            ? null
                                            : new DistrictName(
                                                    district.getNameKm(), district.getNameEn()));
                        })
                .sorted(Comparator.comparing(HospitalResponse::name))
                .toList();
    }
}
