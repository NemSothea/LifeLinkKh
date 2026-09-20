package kh.lifelink.api.hospital;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reference data behind the urgent-request form's hospital dropdown.
 *
 * <p>Split out of {@code HospitalController} for the same reason as {@link
 * kh.lifelink.api.district.DistrictService}: it was one of two areas reaching past the service
 * layer straight into repositories, and consistency is cheaper to keep than to defend.
 *
 * <p>This one earns the layer more plainly than the district list does — it joins two tables, and a
 * join is domain work.
 */
@Service
public class HospitalService {

    private final HospitalRepository hospitals;
    private final DistrictRepository districts;

    HospitalService(HospitalRepository hospitals, DistrictRepository districts) {
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
    @Transactional(readOnly = true)
    public List<HospitalResponse> list() {
        Map<String, District> byCode =
                districts.findAll().stream()
                        .collect(Collectors.toMap(District::getCode, Function.identity()));

        return hospitals.findAll().stream()
                .map(hospital -> toResponse(hospital, byCode))
                .sorted(Comparator.comparing(HospitalResponse::name))
                .toList();
    }

    /**
     * A hospital with no district code, or one naming a district that is not seeded, returns a null
     * district rather than failing the whole list. A dropdown that renders one row without its khan
     * is usable; a 500 on the request form is not.
     */
    private HospitalResponse toResponse(Hospital hospital, Map<String, District> byCode) {
        District district =
                hospital.getDistrictCode() == null ? null : byCode.get(hospital.getDistrictCode());
        return new HospitalResponse(
                hospital.getId(),
                hospital.getName(),
                district == null
                        ? null
                        : new DistrictName(district.getNameKm(), district.getNameEn()));
    }
}
