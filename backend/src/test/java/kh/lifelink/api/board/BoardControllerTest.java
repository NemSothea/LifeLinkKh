package kh.lifelink.api.board;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.board.dto.PublicRequestResponse;
import kh.lifelink.api.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * The board is the only unauthenticated read in this product, so the test that matters most is that
 * it stays unauthenticated — and that nothing else did.
 */
@WebMvcTest(BoardController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class BoardControllerTest {

    @Autowired private MockMvc mvc;

    @MockitoBean private BoardService board;
    @MockitoBean private PublicBoardRateLimiter rateLimiter;

    @Test
    void theBoardIsReadableWithNoCredentialAtAll() throws Exception {
        Mockito.when(rateLimiter.tryAcquire(Mockito.anyString())).thenReturn(true);
        Mockito.when(board.listOpenRequests()).thenReturn(List.<PublicRequestResponse>of());

        mvc.perform(get("/public/requests"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    /** Opening the board must not have opened the portal next to it. */
    @Test
    void thePortalIsStillClosed() throws Exception {
        mvc.perform(get("/portal/requests")).andExpect(status().isUnauthorized());
    }

    /** Nor the admin endpoints. */
    @Test
    void staffProvisioningIsStillClosed() throws Exception {
        mvc.perform(get("/admin/staff")).andExpect(status().isUnauthorized());
    }
}
