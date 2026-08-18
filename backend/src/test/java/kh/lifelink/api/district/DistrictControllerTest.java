package kh.lifelink.api.district;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.UUID;
import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** Web-slice test: no PostgreSQL, so it passes in CI. */
@WebMvcTest(DistrictController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class DistrictControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtService jwt;

    @MockitoBean private DistrictRepository districts;

    private String donorToken() {
        return jwt.issue(UUID.randomUUID(), "DONOR");
    }

    @Test
    void listsDistrictsSortedByKhmerName() throws Exception {
        // Deliberately out of both code order and Latin order, so a pass means the Khmer
        // collation ran rather than that the input happened to be sorted already.
        when(districts.findAll())
                .thenReturn(
                        List.of(
                                district("1204", "ទួលគោក", "Tuol Kouk"),
                                district("1201", "ចំការមន", "Chamkar Mon"),
                                district("1202", "ដូនពេញ", "Doun Penh")));

        mockMvc.perform(get("/districts").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                // ច < ដ < ទ in Khmer alphabetical order.
                .andExpect(jsonPath("$[0].code").value("1201"))
                .andExpect(jsonPath("$[1].code").value("1202"))
                .andExpect(jsonPath("$[2].code").value("1204"))
                .andExpect(jsonPath("$[0].nameKm").value("ចំការមន"))
                .andExpect(jsonPath("$[0].nameEn").value("Chamkar Mon"));
    }

    /**
     * Not an exemption in the deny-by-default chain. The list is 14 public place names, so this is not
     * about secrecy — it is that the chain permits exactly three things, and a fourth added for
     * convenience is how that property erodes.
     */
    @Test
    void requiresAToken() throws Exception {
        mockMvc.perform(get("/districts"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    }

    /** An empty table is a deployment that has not run V3, not an error to invent. */
    @Test
    void anEmptyTableIsAnEmptyList() throws Exception {
        when(districts.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/districts").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    private static District district(String code, String km, String en) {
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
