package com.shopmanagement.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;

// @Configuration - DISABLED: Using SecurityConfig's CORS instead to avoid conflicts
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();

        // Allow credentials (for cookies, auth headers, etc.)
        config.setAllowCredentials(true);

        // Allowed origins / domains
        config.setAllowedOriginPatterns(Arrays.asList(
                "https://*.nammaoorudelivary.in",
                "https://nammaoorudelivary.in",
                "http://localhost:*"
        ));

        // Allow all headers
        config.setAllowedHeaders(Arrays.asList("*"));

        // Allow all standard HTTP methods
        config.setAllowedMethods(Arrays.asList(
                "GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"
        ));

        // Expose specific headers
        config.setExposedHeaders(Arrays.asList(
                "Authorization", "Content-Type", "X-Total-Count"
        ));

        // Cache preflight results for 1 hour
        config.setMaxAge(3600L);

        // Apply to all routes
        source.registerCorsConfiguration("/**", config);

        return new CorsFilter(source);
    }
}
