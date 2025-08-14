package com.shopmanagement.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
public class FileUploadService {

    @Value("${file.upload.path:./uploads}")
    private String uploadPath;

    @Value("${file.upload.allowed-extensions:jpg,jpeg,png,gif,webp}")
    private String allowedExtensions;

    @Value("${file.upload.max-size:10485760}") // 10MB in bytes
    private long maxFileSize;

    public String uploadFile(MultipartFile file, String category) throws IOException {
        validateFile(file);
        
        String fileName = generateFileName(file);
        String categoryPath = category != null ? category + "/" : "";
        Path uploadDir = Paths.get(uploadPath, categoryPath);
        
        // Create directories if they don't exist
        Files.createDirectories(uploadDir);
        
        Path filePath = uploadDir.resolve(fileName);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
        
        String fileUrl = "/" + categoryPath + fileName;
        log.info("File uploaded successfully: {}", fileUrl);
        
        return fileUrl;
    }

    public String uploadShopImage(MultipartFile file, String shopId) throws IOException {
        return uploadFile(file, "shops/" + shopId);
    }

    public boolean deleteFile(String fileUrl) {
        try {
            Path filePath = Paths.get(uploadPath + fileUrl);
            boolean deleted = Files.deleteIfExists(filePath);
            if (deleted) {
                log.info("File deleted successfully: {}", fileUrl);
            } else {
                log.warn("File not found for deletion: {}", fileUrl);
            }
            return deleted;
        } catch (IOException e) {
            log.error("Error deleting file: {}", fileUrl, e);
            return false;
        }
    }

    private void validateFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File cannot be empty");
        }

        if (file.getSize() > maxFileSize) {
            throw new IllegalArgumentException("File size exceeds maximum limit");
        }

        String fileName = file.getOriginalFilename();
        if (fileName == null || fileName.trim().isEmpty()) {
            throw new IllegalArgumentException("File name cannot be empty");
        }

        String extension = getFileExtension(fileName);
        List<String> allowedExts = Arrays.asList(allowedExtensions.split(","));
        
        if (!allowedExts.contains(extension.toLowerCase())) {
            throw new IllegalArgumentException("File type not allowed. Allowed types: " + allowedExtensions);
        }
    }

    private String generateFileName(MultipartFile file) {
        String originalFileName = file.getOriginalFilename();
        String extension = getFileExtension(originalFileName);
        return UUID.randomUUID().toString() + "." + extension;
    }

    private String getFileExtension(String fileName) {
        int lastDotIndex = fileName.lastIndexOf('.');
        if (lastDotIndex > 0 && lastDotIndex < fileName.length() - 1) {
            return fileName.substring(lastDotIndex + 1);
        }
        return "";
    }
}