package kh.lifelink.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Metadata for the generated Swagger UI.
 *
 * <p><strong>This is not the API contract.</strong> The contract is hand-written and lives in
 * {@code docs/fullstack/api-contract/mobile/openapi.yaml} and {@code .../web/openapi.yaml}. Those
 * were written before the code, at M1, which is what let two clients be built against one API
 * without waiting for it — and what makes them able to disagree with the implementation, which is
 * the entire point of having them.
 *
 * <p>What springdoc generates here is derived <em>from</em> the code, so it can never disagree with
 * it. Useful for trying a call against a running stack; useless for catching the implementation
 * being wrong. The description below says so, because a reader who finds Swagger first should not
 * mistake it for the specification.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI lifelinkOpenApi() {
        return new OpenAPI()
                .info(
                        new Info()
                                .title("LifeLink KH API")
                                .version("0.6.0")
                                .description(
                                        """
                                        Generated from the running code — a live console for \
                                        trying calls, not the specification.

                                        The specification is hand-written and contract-first:
                                          * `docs/fullstack/api-contract/mobile/openapi.yaml` \
                                        (Flutter donor/requester app)
                                          * `docs/fullstack/api-contract/web/openapi.yaml` \
                                        (Next.js hospital/admin portal)

                                        Where this page and those files disagree, the files are \
                                        right and the code has drifted.

                                        **Authorize with a bearer token** to try anything but \
                                        `/health`, `/public/**` and the sign-in endpoints. A \
                                        portal token comes from `POST /auth/portal/login`; a \
                                        mobile one comes from `POST /auth/google` or, without \
                                        Firebase configured, `scripts/mint-portal-jwt.py`."""))
                .components(
                        new Components()
                                .addSecuritySchemes(
                                        "bearerAuth",
                                        new SecurityScheme()
                                                .type(SecurityScheme.Type.HTTP)
                                                .scheme("bearer")
                                                .bearerFormat("JWT")))
                // Applied globally so the UI sends the token everywhere. The endpoints that do
                // not need one ignore it; the alternative is annotating every controller.
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
    }
}
