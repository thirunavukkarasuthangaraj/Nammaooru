package com.shopmanagement.service;

import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShopAvailabilityService {

    private final ShopRepository shopRepository;
    private final BusinessHoursService businessHoursService;

    /**
     * Update shop availability based on business hours
     * Runs every 5 minutes
     */
    @Scheduled(fixedRate = 300000) // 5 minutes
    @Transactional
    public void updateShopAvailability() {
        log.debug("Starting scheduled shop availability update");
        
        try {
            List<Shop> allActiveShops = shopRepository.findByIsActiveTrue(PageRequest.of(0, 1000)).getContent();
            
            int openCount = 0;
            int closedCount = 0;
            
            for (Shop shop : allActiveShops) {
                boolean shouldBeOpen = businessHoursService.isShopOpenNow(shop.getId());
                boolean currentlyAvailable = shop.getIsAvailable();
                
                if (shouldBeOpen != currentlyAvailable) {
                    shop.setIsAvailable(shouldBeOpen);
                    shop.setAvailabilityUpdatedAt(LocalDateTime.now());
                    shopRepository.save(shop);
                    
                    log.info("Updated shop availability: {} (ID: {}) - {} -> {}", 
                        shop.getName(), shop.getId(), 
                        currentlyAvailable ? "Available" : "Unavailable",
                        shouldBeOpen ? "Available" : "Unavailable"
                    );
                }
                
                if (shouldBeOpen) {
                    openCount++;
                } else {
                    closedCount++;
                }
            }
            
            log.debug("Shop availability update completed. Open: {}, Closed: {}", openCount, closedCount);
            
        } catch (Exception e) {
            log.error("Error updating shop availability", e);
        }
    }

    /**
     * Get real-time availability status for a shop
     */
    public Map<String, Object> getShopAvailabilityStatus(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
            .orElseThrow(() -> new RuntimeException("Shop not found with ID: " + shopId));
        
        boolean shouldBeOpen = businessHoursService.isShopOpenNow(shopId);
        Map<String, Object> businessHourStatus = businessHoursService.getShopOpenStatus(shopId);
        
        Map<String, Object> result = new HashMap<>();
        result.put("shopId", shopId);
        result.put("shopName", shop.getName());
        result.put("isActive", shop.getIsActive());
        result.put("isAvailable", shop.getIsAvailable());
        result.put("shouldBeOpen", shouldBeOpen);
        result.put("lastUpdated", shop.getAvailabilityUpdatedAt());
        result.put("businessHoursStatus", businessHourStatus);
        result.put("overallStatus", determineOverallStatus(shop, shouldBeOpen));
        return result;
    }
    
    /**
     * Get availability status for multiple shops
     */
    public Map<Long, Map<String, Object>> getBulkShopAvailabilityStatus(List<Long> shopIds) {
        return shopIds.stream()
            .collect(Collectors.toMap(
                shopId -> shopId,
                this::getShopAvailabilityStatus
            ));
    }
    
    /**
     * Force update availability for a specific shop
     */
    @Transactional
    public Map<String, Object> forceUpdateShopAvailability(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
            .orElseThrow(() -> new RuntimeException("Shop not found with ID: " + shopId));
        
        boolean shouldBeOpen = businessHoursService.isShopOpenNow(shopId);
        boolean wasAvailable = shop.getIsAvailable();
        
        shop.setIsAvailable(shouldBeOpen);
        shop.setAvailabilityUpdatedAt(LocalDateTime.now());
        shopRepository.save(shop);
        
        log.info("Force updated shop availability: {} (ID: {}) - {} -> {}", 
            shop.getName(), shop.getId(), 
            wasAvailable ? "Available" : "Unavailable",
            shouldBeOpen ? "Available" : "Unavailable"
        );
        
        return getShopAvailabilityStatus(shopId);
    }
    
    /**
     * Manually override shop availability (admin/shop owner action)
     */
    @Transactional
    public Map<String, Object> overrideShopAvailability(Long shopId, boolean isAvailable, String reason) {
        Shop shop = shopRepository.findById(shopId)
            .orElseThrow(() -> new RuntimeException("Shop not found with ID: " + shopId));
        
        boolean wasAvailable = shop.getIsAvailable();
        
        shop.setIsAvailable(isAvailable);
        shop.setAvailabilityUpdatedAt(LocalDateTime.now());
        shop.setAvailabilityOverrideReason(reason);
        shop.setIsManualOverride(true);
        shopRepository.save(shop);
        
        log.info("Manual override shop availability: {} (ID: {}) - {} -> {} (Reason: {})", 
            shop.getName(), shop.getId(), 
            wasAvailable ? "Available" : "Unavailable",
            isAvailable ? "Available" : "Unavailable",
            reason
        );
        
        return getShopAvailabilityStatus(shopId);
    }
    
    /**
     * Clear manual override and return to automatic mode
     */
    @Transactional
    public Map<String, Object> clearShopAvailabilityOverride(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
            .orElseThrow(() -> new RuntimeException("Shop not found with ID: " + shopId));
        
        shop.setIsManualOverride(false);
        shop.setAvailabilityOverrideReason(null);
        
        // Set availability based on business hours
        boolean shouldBeOpen = businessHoursService.isShopOpenNow(shopId);
        shop.setIsAvailable(shouldBeOpen);
        shop.setAvailabilityUpdatedAt(LocalDateTime.now());
        
        shopRepository.save(shop);
        
        log.info("Cleared manual override for shop: {} (ID: {}) - Now automatic mode", 
            shop.getName(), shop.getId());
        
        return getShopAvailabilityStatus(shopId);
    }
    
    private String determineOverallStatus(Shop shop, boolean shouldBeOpen) {
        if (!shop.getIsActive()) {
            return "INACTIVE";
        }
        
        if (shop.getIsManualOverride()) {
            return shop.getIsAvailable() ? "MANUALLY_OPEN" : "MANUALLY_CLOSED";
        }
        
        if (shouldBeOpen && shop.getIsAvailable()) {
            return "OPEN";
        } else if (!shouldBeOpen && !shop.getIsAvailable()) {
            return "CLOSED";
        } else if (shouldBeOpen && !shop.getIsAvailable()) {
            return "SHOULD_BE_OPEN";
        } else {
            return "SHOULD_BE_CLOSED";
        }
    }
    
    /**
     * Get shops that are currently open
     */
    public List<Map<String, Object>> getCurrentlyOpenShops() {
        List<Shop> activeShops = shopRepository.findByIsActiveTrue(PageRequest.of(0, 1000)).getContent();
        
        return activeShops.stream()
            .filter(shop -> shop.getIsAvailable())
            .map(shop -> {
                Map<String, Object> shopInfo = new HashMap<>();
                shopInfo.put("shopId", shop.getId());
                shopInfo.put("shopName", shop.getName());
                shopInfo.put("city", shop.getCity());
                shopInfo.put("businessType", shop.getBusinessType().toString());
                shopInfo.put("rating", shop.getRating());
                shopInfo.put("status", "OPEN");
                return shopInfo;
            })
            .collect(Collectors.toList());
    }
    
    /**
     * Get availability statistics
     */
    public Map<String, Object> getAvailabilityStatistics() {
        List<Shop> allShops = shopRepository.findAll();
        
        long totalShops = allShops.size();
        long activeShops = allShops.stream().mapToLong(shop -> shop.getIsActive() ? 1 : 0).sum();
        long availableShops = allShops.stream().mapToLong(shop -> shop.getIsAvailable() ? 1 : 0).sum();
        long manualOverrides = allShops.stream().mapToLong(shop -> shop.getIsManualOverride() ? 1 : 0).sum();
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalShops", totalShops);
        stats.put("activeShops", activeShops);
        stats.put("availableShops", availableShops);
        stats.put("unavailableShops", activeShops - availableShops);
        stats.put("manualOverrides", manualOverrides);
        stats.put("automaticMode", activeShops - manualOverrides);
        stats.put("availabilityRate", activeShops > 0 ? (double) availableShops / activeShops * 100 : 0.0);
        stats.put("lastUpdated", LocalDateTime.now());
        return stats;
    }
}