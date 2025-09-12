package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ProductImageResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.MasterProductImage;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.ShopProductImage;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.MasterProductImageRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.product.repository.ShopProductImageRepository;
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
    private final MasterProductImageRepository masterProductImageRepository;
    private final ShopProductRepository shopProductRepository;
    private final ShopProductImageRepository shopProductImageRepository;
    private final ProductMapper productMapper;

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Value("${app.upload.product-images:products}")
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
                .orElseThrow(() -> new RuntimeException(String.format("Product with ID %d not found", productId)));
        
        if (!product.getShop().getId().equals(shopId)) {
            throw new RuntimeException(String.format("Product %d does not belong to shop %d (actual shop: %d)", 
                productId, shopId, product.getShop().getId()));
        }

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
        
        // Copy the primary image to the associated master product if it doesn't have images
        if (!images.isEmpty() && product.getMasterProduct() != null) {
            MasterProduct masterProduct = product.getMasterProduct();
            
            // Only copy image if master product has no images yet
            if (masterProduct.getImages().isEmpty()) {
                ShopProductImage primaryShopImage = images.stream()
                        .filter(ShopProductImage::getIsPrimary)
                        .findFirst()
                        .orElse(images.get(0)); // Fallback to first image if no primary set
                
                log.info("Copying primary image from shop product {} to master product {}", productId, masterProduct.getId());
                
                // Create master product image based on shop product image
                MasterProductImage masterImage = MasterProductImage.builder()
                        .masterProduct(masterProduct)
                        .imageUrl(primaryShopImage.getImageUrl())
                        .altText(primaryShopImage.getAltText())
                        .isPrimary(true)
                        .sortOrder(0)
                        .createdBy(getCurrentUsername())
                        .build();
                
                masterProduct.getImages().add(masterImage);
                masterProductRepository.save(masterProduct);
                log.info("Successfully copied image to master product: {}", masterProduct.getId());
            }
        }
        
        return images.stream()
                .map(productMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductImageResponse> getMasterProductImages(Long productId) {
        // Verify product exists
        masterProductRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + productId));
        
        return masterProductImageRepository.findByMasterProductIdOrderBySortOrderAsc(productId).stream()
                .map(productMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductImageResponse> getShopProductImages(Long shopId, Long productId) {
        // Verify product exists and belongs to shop
        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException(String.format("Product with ID %d not found", productId)));
        
        if (!shopProduct.getShop().getId().equals(shopId)) {
            throw new RuntimeException(String.format("Product %d does not belong to shop %d (actual shop: %d)", 
                productId, shopId, shopProduct.getShop().getId()));
        }
        
        return shopProductImageRepository.findByShopProductIdOrderBySortOrderAsc(productId).stream()
                .map(productMapper::toResponse)
                .toList();
    }

    public void deleteProductImage(Long imageId) {
        log.info("Deleting product image: {}", imageId);
        
        // Try to find in master product images first
        masterProductImageRepository.findById(imageId)
            .ifPresentOrElse(
                image -> {
                    log.info("Found master product image to delete: {}", imageId);
                    
                    // Delete the physical file
                    deleteImageFile(image.getImageUrl());
                    
                    // Check if this was the primary image
                    boolean wasPrimary = image.getIsPrimary();
                    Long productId = image.getMasterProduct().getId();
                    
                    // Delete the image record from database
                    masterProductImageRepository.delete(image);
                    masterProductImageRepository.flush();
                    
                    // If this was primary image, set another as primary
                    if (wasPrimary) {
                        List<MasterProductImage> remainingImages = masterProductImageRepository
                            .findByMasterProductIdOrderBySortOrderAsc(productId);
                        if (!remainingImages.isEmpty()) {
                            MasterProductImage newPrimary = remainingImages.get(0);
                            newPrimary.setIsPrimary(true);
                            masterProductImageRepository.save(newPrimary);
                            log.info("Set new primary image: {} for master product: {}", newPrimary.getId(), productId);
                        }
                    }
                    
                    log.info("Successfully deleted master product image: {}", imageId);
                },
                () -> {
                    // Try shop product images
                    shopProductImageRepository.findById(imageId)
                        .ifPresentOrElse(
                            image -> {
                                log.info("Found shop product image to delete: {}", imageId);
                                
                                // Delete the physical file
                                deleteImageFile(image.getImageUrl());
                                
                                // Check if this was the primary image
                                boolean wasPrimary = image.getIsPrimary();
                                Long productId = image.getShopProduct().getId();
                                
                                // Delete the image record from database
                                shopProductImageRepository.delete(image);
                                shopProductImageRepository.flush();
                                
                                // If this was primary image, set another as primary
                                if (wasPrimary) {
                                    List<ShopProductImage> remainingImages = shopProductImageRepository
                                        .findByShopProductIdOrderBySortOrderAsc(productId);
                                    if (!remainingImages.isEmpty()) {
                                        ShopProductImage newPrimary = remainingImages.get(0);
                                        newPrimary.setIsPrimary(true);
                                        shopProductImageRepository.save(newPrimary);
                                        log.info("Set new primary image: {} for shop product: {}", newPrimary.getId(), productId);
                                    }
                                }
                                
                                log.info("Successfully deleted shop product image: {}", imageId);
                            },
                            () -> {
                                log.error("Product image not found with id: {}", imageId);
                                throw new RuntimeException("Product image not found with id: " + imageId);
                            }
                        );
                }
            );
    }

    public ProductImageResponse setPrimaryImage(Long imageId) {
        log.info("Setting image as primary: {}", imageId);
        
        // Try master product images first
        return masterProductImageRepository.findById(imageId)
                .map(image -> {
                    Long productId = image.getMasterProduct().getId();
                    
                    // Reset all images as non-primary for this product
                    List<MasterProductImage> allImages = masterProductImageRepository
                        .findByMasterProductIdOrderBySortOrderAsc(productId);
                    allImages.forEach(img -> img.setIsPrimary(false));
                    masterProductImageRepository.saveAll(allImages);
                    
                    // Set this image as primary
                    image.setIsPrimary(true);
                    masterProductImageRepository.save(image);
                    
                    log.info("Set master product image {} as primary for product {}", imageId, productId);
                    return productMapper.toResponse(image);
                })
                .orElseGet(() -> {
                    // Try shop product images
                    return shopProductImageRepository.findById(imageId)
                            .map(image -> {
                                Long productId = image.getShopProduct().getId();
                                
                                // Reset all images as non-primary for this product
                                List<ShopProductImage> allImages = shopProductImageRepository
                                    .findByShopProductIdOrderBySortOrderAsc(productId);
                                allImages.forEach(img -> img.setIsPrimary(false));
                                shopProductImageRepository.saveAll(allImages);
                                
                                // Set this image as primary
                                image.setIsPrimary(true);
                                shopProductImageRepository.save(image);
                                
                                log.info("Set shop product image {} as primary for product {}", imageId, productId);
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
            
            // Create directory structure with better error handling
            Path uploadPath = Paths.get(uploadDir, productImageDir, type);
            
            log.info("Attempting to create/access upload directory: {}", uploadPath.toAbsolutePath());
            
            try {
                if (!Files.exists(uploadPath)) {
                    Files.createDirectories(uploadPath);
                    log.info("Created upload directory: {}", uploadPath.toAbsolutePath());
                }
            } catch (IOException e) {
                log.error("Failed to create upload directory: {}. Error: {}", uploadPath.toAbsolutePath(), e.getMessage());
                throw new RuntimeException("Failed to create upload directory: " + uploadPath.toAbsolutePath() + ". Please ensure the application has write permissions.");
            }
            
            // Check if directory is writable
            if (!Files.isWritable(uploadPath)) {
                log.error("Upload directory is not writable: {}", uploadPath.toAbsolutePath());
                throw new RuntimeException("Upload directory is not writable: " + uploadPath.toAbsolutePath() + ". Please check permissions.");
            }
            
            Path filePath = uploadPath.resolve(filename);
            log.info("Saving file to: {}", filePath.toAbsolutePath());
            
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            log.info("Successfully saved file: {}", filePath.toAbsolutePath());
            
            // Return the relative URL path
            return String.format("/uploads/%s/%s/%s", productImageDir, type, filename);
            
        } catch (IOException e) {
            log.error("Error saving image file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to save image file: " + uploadDir + ". " + e.getMessage());
        }
    }

    private void deleteImageFile(String imageUrl) {
        try {
            // Remove leading slash and construct proper path
            String relativePath = imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl;
            Path filePath = Paths.get(uploadDir).resolve(relativePath);
            
            if (Files.exists(filePath)) {
                Files.delete(filePath);
                log.info("Successfully deleted image file: {}", filePath);
            } else {
                log.warn("Image file not found for deletion: {}", filePath);
            }
        } catch (IOException e) {
            log.error("Error deleting image file: {}", imageUrl, e);
            // Don't throw exception - we still want to delete from database even if file deletion fails
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
}