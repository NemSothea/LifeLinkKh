package kh.lifelink.api.donation;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.config.SecurityConfig;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.donation.dto.DonationResponse;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** Web-slice test: no PostgreSQL, so it passes in CI. */
@WebMvcTest(DonationController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class DonationControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtService jwt;

    @MockitoBean private DonationService donations;

    private String donorToken() {
        return jwt.issue(UUID.randomUUID(), "DONOR");
    }

    @Test
    void listsTheCallersOwnDonationHistory() throws Exception {
        when(donations.listForUser(org.mockito.ArgumentMatchers.any()))
                .thenReturn(
                        List.of(
                                new DonationResponse(
                                        UUID.randomUUID(),
                                        LocalDate.of(2026, 6, 14),
                                        new HospitalResponse(
                                                UUID.randomUUID(),
                                                "Calmette Hospital",
                                                new DistrictName("ចំការមន", "Chamkar Mon")),
                                        null)));

        mockMvc.perform(get("/donations/me").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].donatedOn").value("2026-06-14"))
                .andExpect(jsonPath("$[0].hospital.name").value("Calmette Hospital"))
                .andExpect(jsonPath("$[0].bloodRequestId").value(nullValue()));
    }

    @Test
    void requiresAToken() throws Exception {
        mockMvc.perform(get("/donations/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    }

    @Test
    void noDonorProfileYetIsAnEmptyListNotAnError() throws Exception {
        when(donations.listForUser(org.mockito.ArgumentMatchers.any())).thenReturn(List.of());

        mockMvc.perform(get("/donations/me").header("Authorization", "Bearer " + donorToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
