package com.shopmanagement.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;
import java.util.Arrays;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

// CORS is now handled by SecurityConfig.corsConfigurationSource()
// Removed duplicate CORS configuration to avoid conflicts
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Create upload directory if it doesn't exist
        File uploadDirectory = new File(uploadDir);
        if (!uploadDirectory.exists()) {
            uploadDirectory.mkdirs();
        }

        // Get absolute path for the upload directory
        String uploadPath = uploadDirectory.getAbsolutePath();

        // Serve static files from uploads directory at /uploads/**
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath + "/")
                .setCachePeriod(3600)
                .resourceChain(true);

        // Also serve at /api/uploads/** for requests coming through nginx with /api/ prefix
        registry.addResourceHandler("/api/uploads/**")
                .addResourceLocations("file:" + uploadPath + "/")
                .setCachePeriod(3600)
                .resourceChain(true);

        System.out.println("Static resource handler configured:");
        System.out.println("  URL Pattern: /uploads/** and /api/uploads/**");
        System.out.println("  File Location: " + uploadPath);
    }
}