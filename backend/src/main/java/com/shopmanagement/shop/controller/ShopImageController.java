package com.shopmanagement.shop.controller;

import com.shopmanagement.shop.dto.ShopImageResponse;
import com.shopmanagement.shop.entity.ShopImage;
import com.shopmanagement.shop.service.ShopImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/shops/{shopId}/images")
@RequiredArgsConstructor
public class ShopImageController {

    private final ShopImageService shopImageService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ShopImageResponse> uploadShopImage(
            @PathVariable Long shopId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "GALLERY") String imageType,
            @RequestParam(defaultValue = "false") boolean isPrimary) throws IOException {
        
        ShopImage.ImageType type = ShopImage.ImageType.valueOf(imageType.toUpperCase());
        ShopImageResponse response = shopImageService.uploadShopImage(shopId, file, type, isPrimary);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<ShopImageResponse>> getShopImages(@PathVariable Long shopId) {
        List<ShopImageResponse> images = shopImageService.getShopImages(shopId);
        return ResponseEntity.ok(images);
    }

    @GetMapping("/type/{imageType}")
    public ResponseEntity<List<ShopImageResponse>> getShopImagesByType(
            @PathVariable Long shopId,
            @PathVariable String imageType) {
        
        ShopImage.ImageType type = ShopImage.ImageType.valueOf(imageType.toUpperCase());
        List<ShopImageResponse> images = shopImageService.getShopImagesByType(shopId, type);
        return ResponseEntity.ok(images);
    }

    @DeleteMapping("/{imageId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Void> deleteShopImage(@PathVariable Long shopId, @PathVariable Long imageId) {
        shopImageService.deleteShopImage(imageId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{imageId}/primary")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ShopImageResponse> setPrimaryImage(@PathVariable Long shopId, @PathVariable Long imageId) {
        ShopImageResponse response = shopImageService.setPrimaryImage(imageId);
        return ResponseEntity.ok(response);
    }
}