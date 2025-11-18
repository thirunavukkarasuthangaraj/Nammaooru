package com.shopmanagement.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableScheduling
@ConditionalOnProperty(
    name = "app.scheduling.enabled",
    havingValue = "true",
    matchIfMissing = true  // Enable by default if property not set
)
public class SchedulingConfig {
    // Scheduled jobs will only run when app.scheduling.enabled=true
    // This prevents duplicate job execution during zero-downtime deployment
}