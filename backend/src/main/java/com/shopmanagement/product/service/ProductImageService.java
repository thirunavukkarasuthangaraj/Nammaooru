package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ProductImageResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.MasterProductImage;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.ShopProductImage;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProductImageService {

    private final MasterProductRepository masterProductRepository;
    private final ShopProductRepository shopProductRepository;
    private final ProductMapper productMapper;

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Value("${app.upload.product-images:/uploads/products}")
    private String productImageDir;

    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("jpg", "jpeg", "png", "gif", "webp");
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

    public List<ProductImageResponse> uploadMasterProductImages(Long productId, MultipartFile[] files, String[] altTexts) {
        log.info("Uploading {} images for master product: {}", files.length, productId);
        
        MasterProduct product = masterProductRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + productId));

        List<MasterProductImage> images = new ArrayList<>();
        
        for (int i = 0; i < files.length; i++) {
            MultipartFile file = files[i];
            String altText = (altTexts != null && i < altTexts.length) ? altTexts[i] : "";
            
            validateImageFile(file);
            
            String imageUrl = saveImageFile(file, "master", productId);
            
            MasterProductImage image = MasterProductImage.builder()
                    .masterProduct(product)
                    .imageUrl(imageUrl)
                    .altText(altText)
                    .isPrimary(i == 0 && product.getImages().isEmpty()) // First image as primary if no existing images
                    .sortOrder(product.getImages().size() + i)
                    .createdBy(getCurrentUsername())
                    .build();
            
            images.add(image);
            product.getImages().add(image);
        }
        
        masterProductRepository.save(product);
        log.info("Successfully uploaded {} images for master product: {}", images.size(), productId);
        
        return images.stream()
                .map(productMapper::toResponse)
                .toList();
    }

    public List<ProductImageResponse> uploadShopProductImages(Long shopId, Long productId, MultipartFile[] files, String[] altTexts) {
        log.info("Uploading {} images for shop product: {} in shop: {}", files.length, productId, shopId);
        
        ShopProduct product = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));

        List<ShopProductImage> images = new ArrayList<>();
        
        for (int i = 0; i < files.length; i++) {
            MultipartFile file = files[i];
            String altText = (altTexts != null && i < altTexts.length) ? altTexts[i] : "";
            
            validateImageFile(file);
            
            String imageUrl = saveImageFile(file, "shop", productId, shopId);
            
            ShopProductImage image = ShopProductImage.builder()
                    .shopProduct(product)
                    .imageUrl(imageUrl)
                    .altText(altText)
                    .isPrimary(i == 0 && product.getShopImages().isEmpty()) // First image as primary if no existing images
                    .sortOrder(product.getShopImages().size() + i)
                    .createdBy(getCurrentUsername())
                    .build();
            
            images.add(image);
            product.getShopImages().add(image);
        }
        
        shopProductRepository.save(product);
        log.info("Successfully uploaded {} images for shop product: {}", images.size(), productId);
        
        return images.stream()
                .map(productMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductImageResponse> getMasterProductImages(Long productId) {
        MasterProduct product = masterProductRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + productId));
        
        return product.getImages().stream()
                .sorted((a, b) -> Integer.compare(a.getSortOrder(), b.getSortOrder()))
                .map(productMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductImageResponse> getShopProductImages(Long shopId, Long productId) {
        ShopProduct product = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));
        
        return product.getShopImages().stream()
                .sorted((a, b) -> Integer.compare(a.getSortOrder(), b.getSortOrder()))
                .map(productMapper::toResponse)
                .toList();
    }

    public void deleteProductImage(Long imageId) {
        log.info("Deleting product image: {}", imageId);
        
        // Try to find in master product images first
        masterProductRepository.findAll().stream()
                .flatMap(p -> p.getImages().stream())
                .filter(img -> img.getId().equals(imageId))
                .findFirst()
                .ifPresentOrElse(
                    image -> {
                        deleteImageFile(image.getImageUrl());
                        MasterProduct product = image.getMasterProduct();
                        product.getImages().remove(image);
                        
                        // If this was primary image, set another as primary
                        if (image.getIsPrimary() && !product.getImages().isEmpty()) {
                            product.getImages().iterator().next().setIsPrimary(true);
                        }
                        
                        masterProductRepository.save(product);
                    },
                    () -> {
                        // Try shop product images
                        shopProductRepository.findAll().stream()
                                .flatMap(p -> p.getShopImages().stream())
                                .filter(img -> img.getId().equals(imageId))
                                .findFirst()
                                .ifPresentOrElse(
                                    image -> {
                                        deleteImageFile(image.getImageUrl());
                                        ShopProduct product = image.getShopProduct();
                                        product.getShopImages().remove(image);
                                        
                                        // If this was primary image, set another as primary
                                        if (image.getIsPrimary() && !product.getShopImages().isEmpty()) {
                                            product.getShopImages().iterator().next().setIsPrimary(true);
                                        }
                                        
                                        shopProductRepository.save(product);
                                    },
                                    () -> {
                                        throw new RuntimeException("Product image not found with id: " + imageId);
                                    }
                                );
                    }
                );
    }

    public ProductImageResponse setPrimaryImage(Long imageId) {
        log.info("Setting image as primary: {}", imageId);
        
        // Try master product images first
        return masterProductRepository.findAll().stream()
                .flatMap(p -> p.getImages().stream())
                .filter(img -> img.getId().equals(imageId))
                .findFirst()
                .map(image -> {
                    MasterProduct product = image.getMasterProduct();
                    // Reset all images as non-primary
                    product.getImages().forEach(img -> img.setIsPrimary(false));
                    // Set this image as primary
                    image.setIsPrimary(true);
                    masterProductRepository.save(product);
                    return productMapper.toResponse(image);
                })
                .orElseGet(() -> {
                    // Try shop product images
                    return shopProductRepository.findAll().stream()
                            .flatMap(p -> p.getShopImages().stream())
                            .filter(img -> img.getId().equals(imageId))
                            .findFirst()
                            .map(image -> {
                                ShopProduct product = image.getShopProduct();
                                // Reset all images as non-primary
                                product.getShopImages().forEach(img -> img.setIsPrimary(false));
                                // Set this image as primary
                                image.setIsPrimary(true);
                                shopProductRepository.save(product);
                                return productMapper.toResponse(image);
                            })
                            .orElseThrow(() -> new RuntimeException("Product image not found with id: " + imageId));
                });
    }

    public ProductImageResponse updateImageDetails(Long imageId, String altText, Integer sortOrder) {
        // Similar logic to setPrimaryImage but for updating details
        // Implementation would be similar to above patterns
        throw new RuntimeException("Update image details not implemented yet");
    }

    public List<ProductImageResponse> reorderImages(List<Long> imageIds) {
        // Implementation for reordering images
        throw new RuntimeException("Reorder images not implemented yet");
    }

    private void validateImageFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("Image file cannot be empty");
        }
        
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new RuntimeException("Image file size cannot exceed 5MB");
        }
        
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isEmpty()) {
            throw new RuntimeException("Invalid file name");
        }
        
        String extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new RuntimeException("Only image files (jpg, jpeg, png, gif, webp) are allowed");
        }
    }

    private String saveImageFile(MultipartFile file, String type, Long... ids) {
        try {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String uuid = UUID.randomUUID().toString().substring(0, 8);
            String extension = file.getOriginalFilename().substring(file.getOriginalFilename().lastIndexOf("."));
            
            String filename = String.format("%s_%s_%s_%s%s", type, String.join("_", Arrays.stream(ids).map(String::valueOf).toArray(String[]::new)), timestamp, uuid, extension);
            
            // Create directory structure
            Path uploadPath = Paths.get(uploadDir, productImageDir, type);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            
            // Return the relative URL path
            return String.format("%s/%s/%s", productImageDir, type, filename);
            
        } catch (IOException e) {
            log.error("Error saving image file", e);
            throw new RuntimeException("Failed to save image file: " + e.getMessage());
        }
    }

    private void deleteImageFile(String imageUrl) {
        try {
            Path filePath = Paths.get(uploadDir, imageUrl);
            if (Files.exists(filePath)) {
                Files.delete(filePath);
                log.info("Deleted image file: {}", filePath);
            }
        } catch (IOException e) {
            log.error("Error deleting image file: {}", imageUrl, e);
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
}