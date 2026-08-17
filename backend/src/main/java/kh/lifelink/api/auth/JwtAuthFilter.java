package kh.lifelink.api.auth;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.common.error.ErrorResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Turns a bearer token into an authenticated {@code SecurityContext}. The principal is the user's
 * internal UUID — so a controller asks "who is calling" and gets an identity that came from a
 * signed token, never from the request body (TM-AUTH-001 S1).
 *
 * <p>A request with no {@code Authorization} header passes through unauthenticated and is refused
 * later by the filter chain's {@code authenticated()} rule. A request with a *bad* token is refused
 * here and now: letting it continue as anonymous would turn a forged token into a 403 on some
 * endpoints and a silent success on any endpoint that is ever opened up.
 */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private static final String BEARER = "Bearer ";

    private final JwtService jwt;
    private final com.fasterxml.jackson.databind.ObjectMapper json;

    JwtAuthFilter(JwtService jwt, com.fasterxml.jackson.databind.ObjectMapper json) {
        this.jwt = jwt;
        this.json = json;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith(BEARER)) {
            chain.doFilter(request, response);
            return;
        }

        try {
            Claims claims = jwt.parse(header.substring(BEARER.length()));
            UUID userId = UUID.fromString(claims.getSubject());
            String role = claims.get(JwtService.ROLE_CLAIM, String.class);

            var authentication =
                    new UsernamePasswordAuthenticationToken(
                            userId, null, List.of(new SimpleGrantedAuthority("ROLE_" + role)));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (ApiException | IllegalArgumentException ex) {
            // Written directly: this runs before the DispatcherServlet, so @RestControllerAdvice
            // never sees it. Same envelope, so a client cannot tell the two paths apart.
            SecurityContextHolder.clearContext();
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            json.writeValue(
                    response.getOutputStream(),
                    ErrorResponse.of("INVALID_TOKEN", "Not authenticated."));
            return;
        }

        chain.doFilter(request, response);
    }
}
