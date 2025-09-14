package com.shopmanagement.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.multipart.support.StandardServletMultipartResolver;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import jakarta.servlet.MultipartConfigElement;
import java.nio.file.Paths;

@Configuration
public class FileUploadConfig implements WebMvcConfigurer {

    @Value("${app.upload.documents.path:uploads/documents/shops}")
    private String documentUploadPath;

    @Value("${app.upload.documents.path.delivery-partners:uploads/documents/delivery-partners}")
    private String deliveryPartnerDocumentUploadPath;

    @Value("${file.upload.path:./uploads}")
    private String fileUploadPath;

    @Bean
    public StandardServletMultipartResolver multipartResolver() {
        StandardServletMultipartResolver resolver = new StandardServletMultipartResolver();
        return resolver;
    }

    @Bean
    public MultipartConfigElement multipartConfigElement() {
        return new MultipartConfigElement(
                System.getProperty("java.io.tmpdir"), // temp location
                10 * 1024 * 1024, // 10MB max file size
                50 * 1024 * 1024, // 50MB max request size
                1024 * 1024 // 1MB file size threshold
        );
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Serve uploaded shop documents
        String documentPath = Paths.get(documentUploadPath).toAbsolutePath().toString();
        registry.addResourceHandler("/uploads/documents/**")
                .addResourceLocations("file:" + documentPath + "/");

        // Serve uploaded delivery partner documents
        String deliveryPartnerDocumentPath = Paths.get(deliveryPartnerDocumentUploadPath).toAbsolutePath().toString();
        registry.addResourceHandler("/uploads/documents/delivery-partners/**")
                .addResourceLocations("file:" + deliveryPartnerDocumentPath + "/");

        // Serve uploaded shop images (from both locations)
        String imagePath = Paths.get(fileUploadPath).toAbsolutePath().toString();
        registry.addResourceHandler("/shops/**")
                .addResourceLocations(
                    "file:" + imagePath + "/shops/",
                    "file:" + documentPath + "/"
                );

        // Serve product images
        registry.addResourceHandler("/uploads/products/**")
                .addResourceLocations("file:" + imagePath + "/products/");

        // Serve delivery partner profile images (if needed in future)
        registry.addResourceHandler("/delivery-partners/**")
                .addResourceLocations(
                    "file:" + imagePath + "/delivery-partners/",
                    "file:" + deliveryPartnerDocumentPath + "/"
                );
    }
}