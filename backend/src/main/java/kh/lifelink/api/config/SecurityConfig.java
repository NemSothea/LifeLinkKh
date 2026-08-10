package kh.lifelink.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * M2 has NO authentication. Everything is permitted.
 *
 * <p>This class exists only so that M3 tightens an existing configuration instead of introducing
 * security into a running system. It MUST NOT reach a deployed environment — docker-compose is
 * local-only, and the M3 spec replaces this file wholesale.
 *
 * <p>CSRF is disabled because this is a stateless REST API consumed by a Flutter app and a Next.js
 * server, not a session-cookie form app.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http.csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .build();
    }
}
