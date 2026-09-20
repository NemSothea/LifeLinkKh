package kh.lifelink.api.district;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import kh.lifelink.api.district.dto.DistrictResponse;
import org.junit.jupiter.api.Test;

/**
 * The ordering rule, tested where it now lives. This was a controller assertion until the service
 * layer was introduced; it is a domain rule, so it moved with the code rather than being deleted.
 */
class DistrictServiceTest {

    private final DistrictRepository districts = mock(DistrictRepository.class);
    private final DistrictService service = new DistrictService(districts);

    @Test
    void sortsByKhmerNameNotByCodeAndNotByUtf16Order() {
        // Deliberately out of both code order and Latin order, so a pass means the Khmer
        // collation ran rather than that the input happened to be sorted already.
        when(districts.findAll())
                .thenReturn(
                        List.of(
                                district("1204", "ទួលគោក", "Tuol Kouk"),
                                district("1201", "ចំការមន", "Chamkar Mon"),
                                district("1202", "ដូនពេញ", "Doun Penh")));

        List<DistrictResponse> result = service.list();

        // ច < ដ < ទ in Khmer alphabetical order.
        assertThat(result)
                .extracting(DistrictResponse::code)
                .containsExactly("1201", "1202", "1204");
        assertThat(result.get(0).nameKm()).isEqualTo("ចំការមន");
        assertThat(result.get(0).nameEn()).isEqualTo("Chamkar Mon");
    }

    /** An empty table is a deployment that has not run V3, not an error to invent. */
    @Test
    void anEmptyTableIsAnEmptyList() {
        when(districts.findAll()).thenReturn(List.of());

        assertThat(service.list()).isEmpty();
    }

    static District district(String code, String km, String en) {
        District district = new District();
        // Reference data has no setters — the application never writes this table (see District).
        setField(district, "code", code);
        setField(district, "nameKm", km);
        setField(district, "nameEn", en);
        return district;
    }

    private static void setField(District district, String name, String value) {
        try {
            var field = District.class.getDeclaredField(name);
            field.setAccessible(true);
            field.set(district, value);
        } catch (ReflectiveOperationException ex) {
            throw new IllegalStateException("District." + name + " no longer exists", ex);
        }
    }
}
