package com.shopmanagement.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:4200")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Create upload directory if it doesn't exist
        File uploadDirectory = new File(uploadDir);
        if (!uploadDirectory.exists()) {
            uploadDirectory.mkdirs();
        }

        // Get absolute path for the upload directory
        String uploadPath = uploadDirectory.getAbsolutePath();
        
        // Serve static files from uploads directory
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath + "/")
                .setCachePeriod(3600)
                .resourceChain(true);
                
        System.out.println("Static resource handler configured:");
        System.out.println("  URL Pattern: /uploads/**");
        System.out.println("  File Location: " + uploadPath);
    }
}