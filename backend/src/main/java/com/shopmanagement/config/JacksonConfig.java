package com.shopmanagement.config;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Jackson configuration for proper timezone handling.
 * Converts server time to IST and serializes with timezone offset (+05:30).
 */
@Configuration
public class JacksonConfig {

    private static final ZoneId IST_ZONE = ZoneId.of("Asia/Kolkata");
    private static final ZoneId SERVER_ZONE = ZoneId.systemDefault();

    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();

        // Create JavaTimeModule with custom serializer
        JavaTimeModule javaTimeModule = new JavaTimeModule();

        // Custom serializer that converts to IST and adds timezone offset
        javaTimeModule.addSerializer(LocalDateTime.class, new ISTLocalDateTimeSerializer());

        mapper.registerModule(javaTimeModule);

        // Don't write dates as timestamps
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

        return mapper;
    }

    /**
     * Custom serializer that converts LocalDateTime to IST timezone
     * and outputs with +05:30 offset.
     */
    public static class ISTLocalDateTimeSerializer extends StdSerializer<LocalDateTime> {

        private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS");

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
