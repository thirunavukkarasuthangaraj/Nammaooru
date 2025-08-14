package com.shopmanagement.shop.service;

import com.shopmanagement.service.FileUploadService;
import com.shopmanagement.shop.dto.ShopImageResponse;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.entity.ShopImage;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.mapper.ShopMapper;
import com.shopmanagement.shop.repository.ShopImageRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ShopImageService {

    private final ShopImageRepository shopImageRepository;
    private final ShopRepository shopRepository;
    private final FileUploadService fileUploadService;
    private final ShopMapper shopMapper;

    public ShopImageResponse uploadShopImage(Long shopId, MultipartFile file, ShopImage.ImageType imageType, boolean isPrimary) throws IOException {
        log.info("Uploading image for shop ID: {}", shopId);
        
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + shopId));

        String imageUrl = fileUploadService.uploadShopImage(file, shop.getShopId());

        // If this is a primary image, unset other primary images
        if (isPrimary) {
            shopImageRepository.findByShopIdAndIsPrimaryTrue(shopId)
                    .ifPresent(existingPrimary -> {
                        existingPrimary.setIsPrimary(false);
                        shopImageRepository.save(existingPrimary);
                    });
        }

        ShopImage shopImage = ShopImage.builder()
                .shop(shop)
                .imageUrl(imageUrl)
                .imageType(imageType)
                .isPrimary(isPrimary)
                .build();

        ShopImage savedImage = shopImageRepository.save(shopImage);
        log.info("Image uploaded successfully for shop: {}", shop.getShopId());

        return shopMapper.toImageResponse(savedImage);
    }

    @Transactional(readOnly = true)
    public List<ShopImageResponse> getShopImages(Long shopId) {
        List<ShopImage> images = shopImageRepository.findByShopId(shopId);
        return shopMapper.toImageResponseList(images);
    }

    @Transactional(readOnly = true)
    public List<ShopImageResponse> getShopImagesByType(Long shopId, ShopImage.ImageType imageType) {
        List<ShopImage> images = shopImageRepository.findByShopIdAndImageType(shopId, imageType);
        return shopMapper.toImageResponseList(images);
    }

    public void deleteShopImage(Long imageId) {
        log.info("Deleting shop image with ID: {}", imageId);
        
        ShopImage image = shopImageRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found with id: " + imageId));

        // Delete file from storage
        fileUploadService.deleteFile(image.getImageUrl());
        
        // Delete from database
        shopImageRepository.delete(image);
        
        log.info("Shop image deleted successfully: {}", imageId);
    }

    public ShopImageResponse setPrimaryImage(Long imageId) {
        log.info("Setting primary image: {}", imageId);
        
        ShopImage image = shopImageRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found with id: " + imageId));

        // Unset other primary images for this shop
        shopImageRepository.findByShopIdAndIsPrimaryTrue(image.getShop().getId())
                .ifPresent(existingPrimary -> {
                    existingPrimary.setIsPrimary(false);
                    shopImageRepository.save(existingPrimary);
                });

        // Set this image as primary
        image.setIsPrimary(true);
        ShopImage savedImage = shopImageRepository.save(image);

        log.info("Primary image set successfully: {}", imageId);
        return shopMapper.toImageResponse(savedImage);
    }
}