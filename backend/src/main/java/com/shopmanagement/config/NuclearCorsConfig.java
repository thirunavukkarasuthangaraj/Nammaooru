package com.shopmanagement.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// @Configuration - DISABLED to avoid CORS conflicts with SecurityConfig
public class NuclearCorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("*")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Bean
    public org.springframework.web.filter.CorsFilter corsFilter() {
        org.springframework.web.cors.UrlBasedCorsConfigurationSource source = 
            new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        
        org.springframework.web.cors.CorsConfiguration config = 
            new org.springframework.web.cors.CorsConfiguration();
        
        config.setAllowCredentials(true);
        config.addAllowedOriginPattern("*");
        config.addAllowedHeader("*");
        config.addAllowedMethod("*");
        config.setMaxAge(3600L);
        
        source.registerCorsConfiguration("/**", config);
        return new org.springframework.web.filter.CorsFilter(source);
    }
}