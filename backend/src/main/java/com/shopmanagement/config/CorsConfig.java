package com.shopmanagement.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        
        // Production configuration for Cloudflare + Docker
        config.setAllowCredentials(true);
        config.setAllowedOriginPatterns(Arrays.asList(
            "https://*.nammaoorudelivary.in",
            "https://nammaoorudelivary.in",
            "http://localhost:*"
        ));
        
        // Specific origins (uncomment if you want to restrict)
        // config.setAllowedOrigins(Arrays.asList(
        //     "https://nammaoorudelivary.in",
        //     "https://www.nammaoorudelivary.in",
        //     "https://api.nammaoorudelivary.in",
        //     "http://localhost:4200",
        //     "http://localhost:80"
        // ));
        
        // Allow all headers
        config.setAllowedHeaders(Arrays.asList("*"));
        
        // Allow all HTTP methods
        config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"));
        
        // Expose headers
        config.setExposedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Total-Count"));
        
        // Cache preflight response for 1 hour
        config.setMaxAge(3600L);
        
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
    
    // Removed duplicate bean - already defined in SimpleSecurityConfig
}