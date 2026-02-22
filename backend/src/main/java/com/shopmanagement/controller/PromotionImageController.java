package com.shopmanagement.controller;

import com.shopmanagement.service.FileUploadService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
@Slf4j
public class PromotionImageController {

    private final FileUploadService fileUploadService;

    @PostMapping(value = "/promotion", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> uploadPromotionImage(
            @RequestParam("file") MultipartFile file) {

        log.info("Uploading promotion banner image: {}", file.getOriginalFilename());

        try {
            String imageUrl = fileUploadService.uploadFile(file, "promotions");

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Promotion image uploaded successfully");
            response.put("url", imageUrl);
            response.put("path", imageUrl);

            log.info("Promotion image uploaded successfully: {}", imageUrl);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (IOException e) {
            log.error("Failed to upload promotion image", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "5000");
            errorResponse.put("message", "Failed to upload image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid promotion image: {}", e.getMessage());
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "4000");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        }
    }

    @PostMapping(value = "/notification", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> uploadNotificationImage(
            @RequestParam("file") MultipartFile file) {

        log.info("Uploading notification image: {}", file.getOriginalFilename());

        try {
            String imageUrl = fileUploadService.uploadFile(file, "notifications");

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Notification image uploaded successfully");
            response.put("url", imageUrl);
            response.put("path", imageUrl);

            log.info("Notification image uploaded successfully: {}", imageUrl);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (IOException e) {
            log.error("Failed to upload notification image", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "5000");
            errorResponse.put("message", "Failed to upload image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid notification image: {}", e.getMessage());
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "4000");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        }
    }
}
