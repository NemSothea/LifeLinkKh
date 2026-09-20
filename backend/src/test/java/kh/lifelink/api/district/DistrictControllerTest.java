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
import kh.lifelink.api.district.dto.DistrictResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Web-slice test: no PostgreSQL, so it passes in CI. The ordering rule moved to {@link
 * DistrictServiceTest} when the service layer was introduced — what is left here is the HTTP
 * contract and the access rule, which is all a controller is responsible for.
 */
@WebMvcTest(DistrictController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class DistrictControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtService jwt;

    @MockitoBean private DistrictService service;

    private String donorToken() {
        return jwt.issue(UUID.randomUUID(), "DONOR");
    }

    @Test
    void servesTheListTheServiceReturnsInTheOrderItReturnsIt() throws Exception {
        when(service.list())
                .thenReturn(
                        List.of(
                                new DistrictResponse("1201", "ចំការមន", "Chamkar Mon"),
                                new DistrictResponse("1202", "ដូនពេញ", "Doun Penh")));

        mockMvc.perform(get("/districts").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].code").value("1201"))
                .andExpect(jsonPath("$[0].nameKm").value("ចំការមន"))
                .andExpect(jsonPath("$[0].nameEn").value("Chamkar Mon"))
                .andExpect(jsonPath("$[1].code").value("1202"));
    }

    /**
     * Not an exemption in the deny-by-default chain. The list is 14 public place names, so this is
     * not about secrecy — it is that the chain permits exactly three things, and a fourth added for
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
    void anEmptyListSerializesAsAnEmptyArray() throws Exception {
        when(service.list()).thenReturn(List.of());

        mockMvc.perform(get("/districts").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
