package com.shopmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Data
@Configuration
@ConfigurationProperties(prefix = "gemini")
public class GeminiConfig {

    private Boolean enabled;
    private List<String> apiKeys;
    private String model;
    private String apiUrl;
    private RateLimit rateLimit;

    @Data
    public static class RateLimit {
        private Integer perKeyRpm;
        private Integer totalRpm;
    }
}
