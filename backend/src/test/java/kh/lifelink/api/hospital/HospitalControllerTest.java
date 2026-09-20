package kh.lifelink.api.hospital;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.UUID;
import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.config.SecurityConfig;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * The access rule on {@code GET /hospitals} had no test at all before the service split. It is the
 * dropdown behind the urgent-request form, so an accidental exemption here would expose the
 * hospital list to anyone — harmless in itself, but the deny-by-default chain is the property being
 * protected, not the names.
 */
@WebMvcTest(HospitalController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class HospitalControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtService jwt;

    @MockitoBean private HospitalService service;

    private String requesterToken() {
        return jwt.issue(UUID.randomUUID(), "REQUESTER");
    }

    @Test
    void servesTheListTheServiceReturns() throws Exception {
        when(service.list())
                .thenReturn(
                        List.of(
                                new HospitalResponse(
                                        UUID.randomUUID(),
                                        "Calmette Hospital",
                                        new DistrictName("ដូនពេញ", "Doun Penh"))));

        mockMvc.perform(get("/hospitals").header("Authorization", "Bearer " + requesterToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Calmette Hospital"))
                .andExpect(jsonPath("$[0].districtName.km").value("ដូនពេញ"))
                .andExpect(jsonPath("$[0].districtName.en").value("Doun Penh"));
    }

    /** ADR 0003 and the DTO's own note: no coordinates, no address, no contact phone. */
    @Test
    void doesNotLeakCoordinatesOrContactDetails() throws Exception {
        when(service.list())
                .thenReturn(
                        List.of(
                                new HospitalResponse(
                                        UUID.randomUUID(),
                                        "Calmette Hospital",
                                        new DistrictName("ដូនពេញ", "Doun Penh"))));

        mockMvc.perform(get("/hospitals").header("Authorization", "Bearer " + requesterToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].latitude").doesNotExist())
                .andExpect(jsonPath("$[0].longitude").doesNotExist())
                .andExpect(jsonPath("$[0].address").doesNotExist())
                .andExpect(jsonPath("$[0].contactPhone").doesNotExist());
    }

    @Test
    void requiresAToken() throws Exception {
        mockMvc.perform(get("/hospitals"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    }
}
