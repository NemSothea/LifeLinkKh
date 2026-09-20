package kh.lifelink.api.hospital;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.UUID;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.junit.jupiter.api.Test;

/**
 * The hospital list had no test of its own while it lived in the controller. These cover the two
 * things that can actually go wrong in it: the order the dropdown renders in, and a hospital whose
 * district is missing.
 */
class HospitalServiceTest {

    private final HospitalRepository hospitals = mock(HospitalRepository.class);
    private final DistrictRepository districts = mock(DistrictRepository.class);
    private final HospitalService service = new HospitalService(hospitals, districts);

    @Test
    void sortsByNameAndResolvesEachHospitalsDistrict() {
        when(districts.findAll())
                .thenReturn(
                        List.of(
                                district("1202", "ដូនពេញ", "Doun Penh"),
                                district("1206", "មានជ័យ", "Mean Chey")));
        when(hospitals.findAll())
                .thenReturn(
                        List.of(
                                hospital("Preah Kossamak Hospital", "1206"),
                                hospital("Calmette Hospital", "1202")));

        List<HospitalResponse> result = service.list();

        assertThat(result)
                .extracting(HospitalResponse::name)
                .containsExactly("Calmette Hospital", "Preah Kossamak Hospital");
        assertThat(result.get(0).districtName().km()).isEqualTo("ដូនពេញ");
        assertThat(result.get(0).districtName().en()).isEqualTo("Doun Penh");
    }

    /**
     * The request form must still open. A null district code, or one naming a district that is not
     * seeded, drops that hospital's khan — it does not drop the hospital and it does not 500.
     */
    @Test
    void aHospitalWithNoResolvableDistrictStillAppearsWithANullDistrict() {
        when(districts.findAll()).thenReturn(List.of(district("1202", "ដូនពេញ", "Doun Penh")));
        when(hospitals.findAll())
                .thenReturn(
                        List.of(
                                hospital("Anonymous Clinic", null),
                                hospital("Bad Code Hospital", "9999"),
                                hospital("Calmette Hospital", "1202")));

        List<HospitalResponse> result = service.list();

        assertThat(result).hasSize(3);
        assertThat(result.get(0).districtName()).isNull();
        assertThat(result.get(1).districtName()).isNull();
        assertThat(result.get(2).districtName()).isNotNull();
    }

    @Test
    void noHospitalsIsAnEmptyList() {
        when(districts.findAll()).thenReturn(List.of());
        when(hospitals.findAll()).thenReturn(List.of());

        assertThat(service.list()).isEmpty();
    }

    private static District district(String code, String km, String en) {
        District district = new District();
        // Reference data has no setters — the application never writes this table (see District).
        setField(District.class, district, "code", code);
        setField(District.class, district, "nameKm", km);
        setField(District.class, district, "nameEn", en);
        return district;
    }

    private static Hospital hospital(String name, String districtCode) {
        Hospital hospital = new Hospital();
        hospital.setName(name);
        hospital.setDistrictCode(districtCode);
        // The id is database-generated; the list contract carries it, so give it a value.
        setField(Hospital.class, hospital, "id", UUID.randomUUID());
        return hospital;
    }

    private static void setField(Class<?> type, Object target, String name, Object value) {
        try {
            var field = type.getDeclaredField(name);
            field.setAccessible(true);
            field.set(target, value);
        } catch (ReflectiveOperationException ex) {
            throw new IllegalStateException(
                    type.getSimpleName() + "." + name + " no longer exists", ex);
        }
    }
}
