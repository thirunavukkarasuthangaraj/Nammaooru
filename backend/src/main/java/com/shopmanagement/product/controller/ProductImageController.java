package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ProductImageResponse;
import com.shopmanagement.product.service.ProductImageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/products/images")
@RequiredArgsConstructor
@Slf4j
public class ProductImageController {

    private final ProductImageService productImageService;

    @PostMapping(value = "/master/{productId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> uploadMasterProductImages(
            @PathVariable Long productId,
            @RequestParam("images") MultipartFile[] files,
            @RequestParam(required = false) String[] altTexts) {
        
        log.info("Uploading {} images for master product: {}", files.length, productId);
        
        List<ProductImageResponse> images = productImageService.uploadMasterProductImages(
                productId, files, altTexts);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                images,
                "Master product images uploaded successfully"
        ));
    }

    @PostMapping(value = "/shop/{shopId}/{productId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> uploadShopProductImages(
            @PathVariable Long shopId,
            @PathVariable Long productId,
            @RequestParam("images") MultipartFile[] files,
            @RequestParam(required = false) String[] altTexts) {
        
        log.info("Uploading {} images for shop product: {} in shop: {}", files.length, productId, shopId);
        
        List<ProductImageResponse> images = productImageService.uploadShopProductImages(
                shopId, productId, files, altTexts);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                images,
                "Shop product images uploaded successfully"
        ));
    }

    @GetMapping("/master/{productId}")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> getMasterProductImages(
            @PathVariable Long productId) {
        
        log.info("Fetching images for master product: {}", productId);
        List<ProductImageResponse> images = productImageService.getMasterProductImages(productId);
        
        return ResponseEntity.ok(ApiResponse.success(
                images,
                "Master product images fetched successfully"
        ));
    }

    @GetMapping("/shop/{shopId}/{productId}")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> getShopProductImages(
            @PathVariable Long shopId,
            @PathVariable Long productId) {
        
        log.info("Fetching images for shop product: {} in shop: {}", productId, shopId);
        List<ProductImageResponse> images = productImageService.getShopProductImages(shopId, productId);
        
        return ResponseEntity.ok(ApiResponse.success(
                images,
                "Shop product images fetched successfully"
        ));
    }

    @DeleteMapping("/{imageId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Void>> deleteProductImage(@PathVariable Long imageId) {
        log.info("Deleting product image: {}", imageId);
        productImageService.deleteProductImage(imageId);
        
        return ResponseEntity.ok(ApiResponse.success(
                (Void) null,
                "Product image deleted successfully"
        ));
    }

    @PatchMapping("/{imageId}/primary")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ProductImageResponse>> setPrimaryImage(@PathVariable Long imageId) {
        log.info("Setting image as primary: {}", imageId);
        ProductImageResponse image = productImageService.setPrimaryImage(imageId);
        
        return ResponseEntity.ok(ApiResponse.success(
                image,
                "Primary image updated successfully"
        ));
    }

    @PutMapping("/{imageId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ProductImageResponse>> updateImageDetails(
            @PathVariable Long imageId,
            @RequestParam(required = false) String altText,
            @RequestParam(required = false) Integer sortOrder) {
        
        log.info("Updating image details: {}", imageId);
        ProductImageResponse image = productImageService.updateImageDetails(imageId, altText, sortOrder);
        
        return ResponseEntity.ok(ApiResponse.success(
                image,
                "Image details updated successfully"
        ));
    }

    @PostMapping("/{imageId}/reorder")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> reorderImages(
            @PathVariable Long imageId,
            @RequestBody List<Long> imageIds) {
        
        log.info("Reordering product images for image: {}", imageId);
        List<ProductImageResponse> images = productImageService.reorderImages(imageIds);
        
        return ResponseEntity.ok(ApiResponse.success(
                images,
                "Images reordered successfully"
        ));
    }
}