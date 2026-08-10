package kh.lifelink.api.config;

import com.fasterxml.jackson.databind.SerializationFeature;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {

    /**
     * Timestamps serialise as ISO-8601 with offset, never as epoch numbers. Cambodia is UTC+7 and
     * the 56-day cooldown arithmetic must not depend on a client guessing the zone.
     */
    @Bean
    Jackson2ObjectMapperBuilderCustomizer jacksonCustomizer() {
        return builder ->
                builder.featuresToDisable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
                        .failOnUnknownProperties(false);
    }
}
