package com.shopmanagement.product.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
@RequestMapping("/uploads")
public class ImageServeController {

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @GetMapping("/products/{type}/{filename:.+}")
    public ResponseEntity<Resource> serveProductImage(
            @PathVariable String type,
            @PathVariable String filename) {
        try {
            Path filePath = Paths.get(uploadDir, "products", type, filename).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists() && resource.isReadable()) {
                String contentType = Files.probeContentType(filePath);
                if (contentType == null) {
                    contentType = "application/octet-stream";
                }
                
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                System.out.println("File not found: " + filePath.toString());
                return ResponseEntity.notFound().build();
            }
        } catch (MalformedURLException e) {
            System.err.println("Error constructing file URL: " + e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (IOException e) {
            System.err.println("Error reading file: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/documents/**")
    public ResponseEntity<Resource> serveDocument() {
        // Similar implementation for documents if needed
        return ResponseEntity.notFound().build();
    }
}