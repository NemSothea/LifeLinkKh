package kh.lifelink.api.config;

import java.util.List;
import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.common.error.ErrorResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * M3 replaces M2's {@code anyRequest().permitAll()} wholesale, as that class said it would.
 *
 * <p><strong>Deny by default.</strong> Three things are permitted without a token and everything
 * else is authenticated — written as {@code anyRequest().authenticated()}, never as an enumerated
 * deny-list. An endpoint added later must be deliberately opened rather than accidentally left
 * open, because that mistake fails open and every existing test still passes.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final List<String> allowedOrigins;
    private final com.fasterxml.jackson.databind.ObjectMapper json;

    SecurityConfig(
            JwtAuthFilter jwtAuthFilter,
            @Value("${lifelink.cors.allowed-origins}") List<String> allowedOrigins,
            com.fasterxml.jackson.databind.ObjectMapper json) {
        this.jwtAuthFilter = jwtAuthFilter;
        this.allowedOrigins = allowedOrigins;
        this.json = json;
    }

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                // CSRF is irrelevant to a stateless bearer-token API with no cookie to forge — and
                // now disabled for that stated reason rather than by inheritance from M2.
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // No JSESSIONID, no server-side session. The JWT is the session.
                .sessionManagement(
                        session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(
                        auth ->
                                auth.requestMatchers(HttpMethod.OPTIONS, "/**")
                                        .permitAll()
                                        .requestMatchers(HttpMethod.GET, "/health")
                                        .permitAll()
                                        .requestMatchers(HttpMethod.POST, "/auth/google")
                                        .permitAll()
                                        // FR-PORTAL-001. RBAC scoped by hospital happens in
                                        // PortalService; this is the role half — a DONOR or
                                        // REQUESTER JWT gets 403 before the controller runs.
                                        .requestMatchers("/portal/**")
                                        .hasAnyRole("HOSPITAL", "ADMIN")
                                        // TM-AUTH-001 E1 — staff provisioning. HOSPITAL and
                                        // REQUESTER/DONOR JWTs get 403 before AdminController runs.
                                        .requestMatchers("/admin/**")
                                        .hasRole("ADMIN")
                                        .anyRequest()
                                        .authenticated())
                .exceptionHandling(
                        handling ->
                                handling
                                        .authenticationEntryPoint(
                                                (request, response, ex) -> {
                                                    // Same envelope as every other error,
                                                    // serialised the same way. A caller cannot
                                                    // tell "no token" from "bad token", which is
                                                    // deliberate.
                                                    response.setStatus(401);
                                                    response.setContentType(
                                                            MediaType.APPLICATION_JSON_VALUE);
                                                    json.writeValue(
                                                            response.getOutputStream(),
                                                            ErrorResponse.of(
                                                                    "UNAUTHENTICATED",
                                                                    "Not authenticated."));
                                                })
                                        // The `.hasAnyRole("HOSPITAL", "ADMIN")` rule on
                                        // /portal/** is refused here, in the filter chain,
                                        // before any controller runs — GlobalExceptionHandler
                                        // never sees it. Without this, a DONOR JWT hitting the
                                        // portal gets Spring's default 403 page instead of the
                                        // one error envelope every other endpoint returns.
                                        .accessDeniedHandler(
                                                (request, response, ex) -> {
                                                    response.setStatus(403);
                                                    response.setContentType(
                                                            MediaType.APPLICATION_JSON_VALUE);
                                                    json.writeValue(
                                                            response.getOutputStream(),
                                                            ErrorResponse.of(
                                                                    "ROLE_NOT_ALLOWED",
                                                                    "Not allowed for this "
                                                                            + "account's role."));
                                                }))
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    /**
     * An explicit allow-list (ASVS baseline, API row). Never {@code *} — which would also be
     * incompatible with credentialed requests, so a wildcard here is both a finding and a bug.
     */
    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(allowedOrigins);
        // DELETE is here for DELETE /auth/fcm-token (sign-out). The Flutter app is native and never
        // preflights, but the portal is a browser and would fail CORS without it.
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
