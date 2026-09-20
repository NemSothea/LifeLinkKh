package kh.lifelink.api.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.health.HealthController;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Swagger is documentation, not a product surface, and it describes every endpoint this API has. On
 * a deployment that is a free map of the attack surface, so {@code SecurityConfig} permits its
 * paths only while springdoc is actually enabled — the default being disabled.
 *
 * <p>The failure this guards against is silent: someone adds a blanket {@code /v3/api-docs/**}
 * permit "so the docs work", every existing test still passes, and the deployment starts serving an
 * endpoint inventory to anyone who asks. Nothing else in the suite would notice.
 *
 * <p>The enabled case is not asserted here. It needs springdoc's own auto-configuration, which a
 * {@code @WebMvcTest} slice does not load — {@code docs/demo-runbook.md} covers checking the UI by
 * hand on a running stack.
 */
@WebMvcTest(HealthController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
@TestPropertySource(properties = "springdoc.api-docs.enabled=false")
class SwaggerExposureTest {

    @Autowired private MockMvc mockMvc;

    @Test
    void apiDocsIsNotReachableWithoutATokenWhileSwaggerIsDisabled() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    }

    @Test
    void swaggerUiIsNotReachableWithoutATokenWhileSwaggerIsDisabled() throws Exception {
        mockMvc.perform(get("/swagger-ui/index.html"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    }

    /**
     * The control: the exemptions that are supposed to exist still do. A test that only asserts
     * denials would also pass if the whole chain were broken shut.
     */
    @Test
    void healthIsStillOpen() throws Exception {
        mockMvc.perform(get("/health")).andExpect(status().isOk());
    }
}
