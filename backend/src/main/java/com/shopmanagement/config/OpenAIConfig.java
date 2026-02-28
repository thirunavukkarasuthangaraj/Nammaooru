package com.shopmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "openai")
public class OpenAIConfig {

    private Boolean enabled = false;
    private String apiKey;
    private String model = "whisper-1";
    private String apiUrl = "https://api.openai.com/v1/audio/transcriptions";
}
