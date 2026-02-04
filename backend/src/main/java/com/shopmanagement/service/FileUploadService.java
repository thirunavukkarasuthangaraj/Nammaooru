package com.shopmanagement.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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

        // Include /uploads prefix for proper serving
        String fileUrl = "/uploads/" + categoryPath + fileName;
        log.info("File uploaded successfully: {}", fileUrl);

        return fileUrl;
    }

    /**
     * Upload an audio/voice file (mp3, wav, m4a, aac, ogg, webm)
     */
    public String uploadVoiceFile(MultipartFile file, String category) throws IOException {
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
        String extension = getFileExtension(fileName).toLowerCase();
        List<String> allowedAudioExts = Arrays.asList("mp3", "wav", "m4a", "aac", "ogg", "webm", "mp4");
        if (!allowedAudioExts.contains(extension)) {
            throw new IllegalArgumentException("Audio file type not allowed. Allowed types: " + String.join(",", allowedAudioExts));
        }

        String generatedName = UUID.randomUUID().toString() + "." + extension;
        String categoryPath = category != null ? category + "/" : "";
        Path uploadDir = Paths.get(uploadPath, categoryPath);
        Files.createDirectories(uploadDir);

        Path filePath = uploadDir.resolve(generatedName);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        String fileUrl = "/uploads/" + categoryPath + generatedName;
        log.info("Voice file uploaded successfully: {}", fileUrl);
        return fileUrl;
    }

    public String uploadShopImage(MultipartFile file, String shopId) throws IOException {
        return uploadFile(file, "shops/" + shopId);
    }

    /**
     * Upload combo banner image
     */
    public String uploadComboImage(MultipartFile file, Long shopId, Long comboId) throws IOException {
        validateFile(file);

        String fileName = generateFileName(file);
        String categoryPath = "combos/" + shopId + "/" + (comboId != null ? comboId : "temp") + "/";
        Path uploadDir = Paths.get(uploadPath, categoryPath);

        // Create directories if they don't exist
        Files.createDirectories(uploadDir);

        Path filePath = uploadDir.resolve(fileName);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        String fileUrl = "/uploads/" + categoryPath + fileName;
        log.info("Combo image uploaded successfully: {}", fileUrl);

        return fileUrl;
    }

    /**
     * Upload delivery proof with image processing and watermarking
     */
    public String uploadDeliveryProof(MultipartFile file, Long orderId, String proofType) throws IOException {
        validateFile(file);

        // Process image (compress and add watermark)
        BufferedImage processedImage = processDeliveryImage(file, orderId, proofType);

        // Generate file name and path
        String fileName = generateDeliveryFileName(orderId, proofType);
        String categoryPath = "delivery-proof/" + orderId + "/" + proofType + "/";
        Path uploadDir = Paths.get(uploadPath, categoryPath);

        // Create directories if they don't exist
        Files.createDirectories(uploadDir);

        // Save processed image
        Path filePath = uploadDir.resolve(fileName);
        String extension = getFileExtension(file.getOriginalFilename());

        try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
            ImageIO.write(processedImage, extension.toLowerCase(), fos);
        }

        String fileUrl = "/" + categoryPath + fileName;
        log.info("Delivery proof uploaded successfully: {}", fileUrl);

        return fileUrl;
    }

    /**
     * Upload signature with processing
     */
    public String uploadSignature(MultipartFile file, Long orderId) throws IOException {
        validateFile(file);

        // Process signature image
        BufferedImage processedImage = processSignatureImage(file, orderId);

        // Generate file name and path
        String fileName = generateSignatureFileName(orderId);
        String categoryPath = "delivery-proof/" + orderId + "/signature/";
        Path uploadDir = Paths.get(uploadPath, categoryPath);

        // Create directories if they don't exist
        Files.createDirectories(uploadDir);

        // Save processed signature
        Path filePath = uploadDir.resolve(fileName);
        String extension = getFileExtension(file.getOriginalFilename());

        try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
            ImageIO.write(processedImage, extension.toLowerCase(), fos);
        }

        String fileUrl = "/" + categoryPath + fileName;
        log.info("Signature uploaded successfully: {}", fileUrl);

        return fileUrl;
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

    /**
     * Process delivery image with compression and watermarking
     */
    private BufferedImage processDeliveryImage(MultipartFile file, Long orderId, String proofType) throws IOException {
        BufferedImage originalImage = ImageIO.read(file.getInputStream());

        // Resize image if too large (max 1024x1024)
        BufferedImage resizedImage = resizeImage(originalImage, 1024, 1024);

        // Add watermark
        BufferedImage watermarkedImage = addWatermark(resizedImage, orderId, proofType);

        return watermarkedImage;
    }

    /**
     * Process signature image
     */
    private BufferedImage processSignatureImage(MultipartFile file, Long orderId) throws IOException {
        BufferedImage originalImage = ImageIO.read(file.getInputStream());

        // Resize signature if too large (max 512x512)
        BufferedImage resizedImage = resizeImage(originalImage, 512, 512);

        // Add timestamp to signature
        BufferedImage timestampedImage = addTimestamp(resizedImage, orderId);

        return timestampedImage;
    }

    /**
     * Resize image while maintaining aspect ratio
     */
    private BufferedImage resizeImage(BufferedImage originalImage, int maxWidth, int maxHeight) {
        int originalWidth = originalImage.getWidth();
        int originalHeight = originalImage.getHeight();

        // Calculate new dimensions while maintaining aspect ratio
        int newWidth = originalWidth;
        int newHeight = originalHeight;

        if (originalWidth > maxWidth) {
            newWidth = maxWidth;
            newHeight = (newWidth * originalHeight) / originalWidth;
        }

        if (newHeight > maxHeight) {
            newHeight = maxHeight;
            newWidth = (newHeight * originalWidth) / originalHeight;
        }

        // Only resize if image is larger than max dimensions
        if (newWidth < originalWidth || newHeight < originalHeight) {
            BufferedImage resizedImage = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
            Graphics2D g2d = resizedImage.createGraphics();
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2d.drawImage(originalImage, 0, 0, newWidth, newHeight, null);
            g2d.dispose();
            return resizedImage;
        }

        return originalImage;
    }

    /**
     * Add watermark to delivery proof image
     */
    private BufferedImage addWatermark(BufferedImage originalImage, Long orderId, String proofType) {
        BufferedImage watermarkedImage = new BufferedImage(
            originalImage.getWidth(),
            originalImage.getHeight(),
            BufferedImage.TYPE_INT_RGB
        );

        Graphics2D g2d = watermarkedImage.createGraphics();

        // Draw original image
        g2d.drawImage(originalImage, 0, 0, null);

        // Set up watermark
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setColor(new Color(255, 255, 255, 128)); // Semi-transparent white
        g2d.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 24));

        // Create watermark text
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String watermarkText = String.format("NammaOoru - Order #%d\n%s - %s", orderId, proofType.toUpperCase(), timestamp);

        // Position watermark at bottom right
        FontMetrics fontMetrics = g2d.getFontMetrics();
        String[] lines = watermarkText.split("\n");
        int y = originalImage.getHeight() - (lines.length * fontMetrics.getHeight()) - 10;

        for (String line : lines) {
            int x = originalImage.getWidth() - fontMetrics.stringWidth(line) - 10;
            g2d.drawString(line, x, y);
            y += fontMetrics.getHeight();
        }

        g2d.dispose();
        return watermarkedImage;
    }

    /**
     * Add timestamp to signature
     */
    private BufferedImage addTimestamp(BufferedImage originalImage, Long orderId) {
        BufferedImage timestampedImage = new BufferedImage(
            originalImage.getWidth(),
            originalImage.getHeight(),
            BufferedImage.TYPE_INT_RGB
        );

        Graphics2D g2d = timestampedImage.createGraphics();

        // Draw original image
        g2d.drawImage(originalImage, 0, 0, null);

        // Set up timestamp
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setColor(new Color(0, 0, 0, 180)); // Semi-transparent black
        g2d.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 12));

        // Create timestamp text
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String timestampText = String.format("Order #%d - %s", orderId, timestamp);

        // Position timestamp at bottom
        FontMetrics fontMetrics = g2d.getFontMetrics();
        int x = 10;
        int y = originalImage.getHeight() - 10;
        g2d.drawString(timestampText, x, y);

        g2d.dispose();
        return timestampedImage;
    }

    /**
     * Generate unique file name for delivery proof
     */
    private String generateDeliveryFileName(Long orderId, String proofType) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        return String.format("order_%d_%s_%s_%s.jpg", orderId, proofType, timestamp, UUID.randomUUID().toString().substring(0, 8));
    }

    /**
     * Generate unique file name for signature
     */
    private String generateSignatureFileName(Long orderId) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        return String.format("order_%d_signature_%s_%s.jpg", orderId, timestamp, UUID.randomUUID().toString().substring(0, 8));
    }
}