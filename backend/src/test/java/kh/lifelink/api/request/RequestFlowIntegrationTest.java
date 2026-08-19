package kh.lifelink.api.request;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.notify.RequestAlertNotifier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * The M4 loop end to end over real HTTP against real PostgreSQL: a requester posts, a donor is
 * matched, the donor accepts, and the contact appears — and at no point does any response body
 * contain a donor coordinate.
 *
 * <p>Only FCM is mocked. It is the one dependency that reaches outside the machine, and {@code
 * RequestAlertNotifier} is written never to throw, so faking it changes no control flow the rest of
 * the test depends on.
 */
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
@ActiveProfiles("test")
class RequestFlowIntegrationTest {

    @Container @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @MockitoBean private RequestAlertNotifier notifier;

    @Autowired private MockMvc mvc;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private JwtService jwt;

    private final ObjectMapper json = new ObjectMapper();

    private UUID requesterId;
    private UUID donorUserId;
    private UUID donorProfileId;
    private UUID calmetteId;

    @BeforeEach
    void setUp() {
        jdbc.update("DELETE FROM request_matches");
        jdbc.update("DELETE FROM blood_requests");
        jdbc.update("DELETE FROM donor_profiles");
        jdbc.update("DELETE FROM users");

        calmetteId =
                jdbc.queryForObject(
                        "SELECT id FROM hospitals WHERE name = 'Calmette Hospital'", UUID.class);

        requesterId = user("uid-requester", "REQUESTER");
        donorUserId = user("uid-donor", "DONOR");

        // O- donor, about 1 km north of Calmette: compatible with an A+ patient, eligible,
        // available.
        jdbc.update(
                "INSERT INTO donor_profiles (user_id, full_name, blood_type, district_code,"
                        + " is_available, latitude, longitude)"
                        + " VALUES (?, 'Dara', 'O-', '1202', true, 11.59033, 104.91569)",
                donorUserId);
        donorProfileId =
                jdbc.queryForObject(
                        "SELECT id FROM donor_profiles WHERE user_id = ?", UUID.class, donorUserId);

        when(notifier.alert(any(), anyString(), anyString(), any()))
                .thenReturn(Set.of(donorProfileId));
    }

    @Test
    void aRequesterPostsADonorAcceptsAndOnlyThenSeesTheContact() throws Exception {
        // 1. The requester posts. Matching and the alert run inside this call.
        JsonNode created =
                body(
                        mvc.perform(
                                        post("/requests")
                                                .header(
                                                        "Authorization",
                                                        bearer(requesterId, "REQUESTER"))
                                                .contentType(MediaType.APPLICATION_JSON)
                                                .content(
                                                        """
                                                        {"patientBloodType":"A+","unitsNeeded":1,
                                                         "hospitalId":"%s","urgency":"CRITICAL",
                                                         "contactName":"Sokha","contactPhone":"012345678"}
                                                        """
                                                                .formatted(calmetteId)))
                                .andReturn());

        assertThat(created.get("alertedCount").asInt()).isEqualTo(1);
        assertThat(created.get("acceptedCount").asInt()).isZero();
        assertThat(created.get("status").asText()).isEqualTo("OPEN");
        assertThat(created.get("hospital").get("districtName").get("km").asText()).isNotBlank();
        UUID requestId = UUID.fromString(created.get("id").asText());

        // 2. The donor sees it in their inbox, with a rounded distance and no contact yet.
        JsonNode inbox =
                body(
                        mvc.perform(get("/matches/me").header("Authorization", donorToken()))
                                .andReturn());
        assertThat(inbox).hasSize(1);
        JsonNode match = inbox.get(0);
        assertThat(match.get("myBloodType").asText()).isEqualTo("O-");
        assertThat(match.get("response").isNull()).isTrue();
        assertThat(match.get("request").get("requesterContact").isNull()).isTrue();

        BigDecimal distance = match.get("request").get("distanceKm").decimalValue();
        assertThat(distance.remainder(new BigDecimal("0.5"))).isEqualByComparingTo(BigDecimal.ZERO);

        // 3. Before accepting, the request detail still reveals nothing.
        JsonNode beforeAccepting =
                body(
                        mvc.perform(
                                        get("/requests/" + requestId)
                                                .header("Authorization", donorToken()))
                                .andReturn());
        assertThat(beforeAccepting.get("requesterContact").isNull()).isTrue();

        // 4. The donor accepts. This is the one call that reveals a phone number.
        UUID matchId = UUID.fromString(match.get("matchId").asText());
        JsonNode accepted =
                body(
                        mvc.perform(
                                        post("/matches/" + matchId + "/respond")
                                                .header("Authorization", donorToken())
                                                .contentType(MediaType.APPLICATION_JSON)
                                                .content("{\"response\":\"ACCEPTED\"}"))
                                .andReturn());

        assertThat(accepted.get("requesterContact").get("phone").asText()).isEqualTo("012345678");
        assertThat(accepted.get("requesterContact").get("displayName").asText()).isEqualTo("Sokha");
        // Unverified in this build, and the client is required to say so (ADR 0002).
        assertThat(accepted.get("requesterContact").get("phoneVerified").asBoolean()).isFalse();

        // 5. Answering twice is a conflict — one response, never overwritten.
        mvc.perform(
                        post("/matches/" + matchId + "/respond")
                                .header("Authorization", donorToken())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"response\":\"DECLINED\"}"))
                .andExpect(
                        org.springframework.test.web.servlet.result.MockMvcResultMatchers.status()
                                .isConflict());

        // 6. The requester's own view now counts the acceptance.
        JsonNode mine =
                body(
                        mvc.perform(
                                        get("/requests/me")
                                                .header(
                                                        "Authorization",
                                                        bearer(requesterId, "REQUESTER")))
                                .andReturn());
        assertThat(mine.get(0).get("acceptedCount").asInt()).isEqualTo(1);
        // Accepting does not close the request — that is the creator's call (ADR 0008 decision 2).
        assertThat(mine.get(0).get("status").asText()).isEqualTo("OPEN");
    }

    /**
     * ADR 0003 and TM-AUTH-001 finding I1, as one assertion over every M4 response a donor or a
     * requester can reach. This is the test the ADR asked for: no endpoint returns a donor
     * coordinate, under any name.
     */
    @Test
    void noResponseInThisFlowEverContainsADonorCoordinate() throws Exception {
        String requestId =
                body(mvc.perform(
                                        post("/requests")
                                                .header(
                                                        "Authorization",
                                                        bearer(requesterId, "REQUESTER"))
                                                .contentType(MediaType.APPLICATION_JSON)
                                                .content(
                                                        """
                                                                {"patientBloodType":"A+","unitsNeeded":2,
                                                                 "hospitalId":"%s","urgency":"URGENT",
                                                                 "contactName":"Sokha","contactPhone":"012345678"}
                                                                """
                                                                .formatted(calmetteId)))
                                .andReturn())
                        .get("id")
                        .asText();

        String[] bodies = {
            raw(
                    mvc.perform(
                                    get("/requests/me")
                                            .header(
                                                    "Authorization",
                                                    bearer(requesterId, "REQUESTER")))
                            .andReturn()),
            raw(
                    mvc.perform(
                                    get("/requests/" + requestId)
                                            .header(
                                                    "Authorization",
                                                    bearer(requesterId, "REQUESTER")))
                            .andReturn()),
            raw(mvc.perform(get("/matches/me").header("Authorization", donorToken())).andReturn()),
            raw(
                    mvc.perform(get("/requests/" + requestId).header("Authorization", donorToken()))
                            .andReturn()),
            raw(mvc.perform(get("/hospitals").header("Authorization", donorToken())).andReturn()),
        };

        for (String payload : bodies) {
            assertThat(payload)
                    .doesNotContain("latitude")
                    .doesNotContain("longitude")
                    // The donor's actual stored coordinate, in case it ever leaks under another
                    // name.
                    .doesNotContain("11.59033")
                    .doesNotContain("104.91569");
        }
    }

    // ---------------------------------------------------------------------

    private UUID user(String uid, String role) {
        jdbc.update("INSERT INTO users (firebase_uid, role) VALUES (?, ?)", uid, role);
        return jdbc.queryForObject("SELECT id FROM users WHERE firebase_uid = ?", UUID.class, uid);
    }

    private String donorToken() {
        return bearer(donorUserId, "DONOR");
    }

    private String bearer(UUID userId, String role) {
        return "Bearer " + jwt.issue(userId, role);
    }

    private JsonNode body(MvcResult result) throws Exception {
        return json.readTree(raw(result));
    }

    private String raw(MvcResult result) throws Exception {
        return result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
    }
}
