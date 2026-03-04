package com.shopmanagement.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "microservice.user-service.enabled", havingValue = "true", matchIfMissing = false)
public class UserServiceHealthIndicator implements HealthIndicator {

    private final MicroserviceProperties microserviceProperties;
    private final RestTemplate restTemplate;

    private volatile boolean userServiceUp = false;
    private volatile String lastError = null;
    private volatile long lastCheckTime = 0;

    @Scheduled(fixedRate = 30000) // Check every 30 seconds
    public void checkUserServiceHealth() {
        try {
            String url = microserviceProperties.getUrl() + "/actuator/health";
            restTemplate.getForEntity(url, String.class);
            userServiceUp = true;
            lastError = null;
            log.debug("[HealthCheck] User-service is UP at {}", microserviceProperties.getUrl());
        } catch (Exception e) {
            userServiceUp = false;
            lastError = e.getMessage();
            log.warn("[HealthCheck] User-service is DOWN: {}", e.getMessage());
        }
        lastCheckTime = System.currentTimeMillis();
    }

    @Override
    public Health health() {
        if (userServiceUp) {
            return Health.up()
                    .withDetail("url", microserviceProperties.getUrl())
                    .withDetail("lastCheck", lastCheckTime)
                    .build();
        } else {
            return Health.down()
                    .withDetail("url", microserviceProperties.getUrl())
                    .withDetail("error", lastError != null ? lastError : "Not checked yet")
                    .withDetail("lastCheck", lastCheckTime)
                    .build();
        }
    }
}
