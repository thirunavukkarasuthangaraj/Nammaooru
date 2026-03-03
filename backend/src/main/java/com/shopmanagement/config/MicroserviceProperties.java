package com.shopmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "microservice.user-service")
public class MicroserviceProperties {

    private boolean enabled = false;
    private String url = "https://user-api.nammaoorudelivary.in";
}
