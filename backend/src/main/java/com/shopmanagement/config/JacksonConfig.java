package com.shopmanagement.config;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Jackson configuration for proper timezone handling.
 * Converts server time to IST and serializes with timezone offset (+05:30).
 * Uses Jackson2ObjectMapperBuilderCustomizer to preserve Spring Boot's default configurations.
 */
@Configuration
public class JacksonConfig {

    private static final ZoneId IST_ZONE = ZoneId.of("Asia/Kolkata");
    private static final ZoneId SERVER_ZONE = ZoneId.systemDefault();

    @Bean
    public Jackson2ObjectMapperBuilderCustomizer jsonCustomizer() {
        return builder -> {
            // Create JavaTimeModule with custom serializer
            JavaTimeModule javaTimeModule = new JavaTimeModule();
            javaTimeModule.addSerializer(LocalDateTime.class, new ISTLocalDateTimeSerializer());

            builder.modules(javaTimeModule);
            builder.featuresToDisable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        };
    }

    /**
     * Custom serializer that converts LocalDateTime to IST timezone
     * and outputs with +05:30 offset.
     */
    public static class ISTLocalDateTimeSerializer extends StdSerializer<LocalDateTime> {

        public ISTLocalDateTimeSerializer() {
            super(LocalDateTime.class);
        }

        @Override
        public void serialize(LocalDateTime value, JsonGenerator gen, SerializerProvider provider) throws IOException {
            if (value == null) {
                gen.writeNull();
                return;
            }

            // Convert from server timezone to IST
            ZonedDateTime serverTime = value.atZone(SERVER_ZONE);
            ZonedDateTime istTime = serverTime.withZoneSameInstant(IST_ZONE);

            // Format as ISO 8601 with IST offset
            String formatted = istTime.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
            gen.writeString(formatted);
        }
    }
}
