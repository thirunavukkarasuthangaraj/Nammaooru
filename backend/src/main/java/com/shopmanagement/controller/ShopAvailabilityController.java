package com.shopmanagement.controller;

import com.shopmanagement.service.ShopAvailabilityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shop-availability")
@RequiredArgsConstructor
@Slf4j
public class ShopAvailabilityController {

    private final ShopAvailabilityService shopAvailabilityService;

    @GetMapping("/{shopId}/status")
    public ResponseEntity<Map<String, Object>> getShopAvailabilityStatus(@PathVariable Long shopId) {
        log.debug("Getting availability status for shop: {}", shopId);
        Map<String, Object> status = shopAvailabilityService.getShopAvailabilityStatus(shopId);
        return ResponseEntity.ok(status);
    }

    @GetMapping("/bulk-status")
    public ResponseEntity<Map<Long, Map<String, Object>>> getBulkShopAvailabilityStatus(
            @RequestParam List<Long> shopIds) {
        log.debug("Getting bulk availability status for shops: {}", shopIds);
        Map<Long, Map<String, Object>> statuses = shopAvailabilityService.getBulkShopAvailabilityStatus(shopIds);
        return ResponseEntity.ok(statuses);
    }

    @PostMapping("/{shopId}/force-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> forceUpdateShopAvailability(@PathVariable Long shopId) {
        log.info("Force updating availability for shop: {}", shopId);
        Map<String, Object> status = shopAvailabilityService.forceUpdateShopAvailability(shopId);
        return ResponseEntity.ok(status);
    }

    @PostMapping("/{shopId}/override")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> overrideShopAvailability(
            @PathVariable Long shopId,
            @RequestParam boolean isAvailable,
            @RequestParam(required = false) String reason) {
        log.info("Manual override availability for shop: {} - Available: {} - Reason: {}", 
            shopId, isAvailable, reason);
        Map<String, Object> status = shopAvailabilityService.overrideShopAvailability(shopId, isAvailable, reason);
        return ResponseEntity.ok(status);
    }

    @PostMapping("/{shopId}/clear-override")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> clearShopAvailabilityOverride(@PathVariable Long shopId) {
        log.info("Clearing manual override for shop: {}", shopId);
        Map<String, Object> status = shopAvailabilityService.clearShopAvailabilityOverride(shopId);
        return ResponseEntity.ok(status);
    }

    @GetMapping("/currently-open")
    public ResponseEntity<List<Map<String, Object>>> getCurrentlyOpenShops() {
        log.debug("Getting currently open shops");
        List<Map<String, Object>> openShops = shopAvailabilityService.getCurrentlyOpenShops();
        return ResponseEntity.ok(openShops);
    }

    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> getAvailabilityStatistics() {
        log.debug("Getting availability statistics");
        Map<String, Object> stats = shopAvailabilityService.getAvailabilityStatistics();
        return ResponseEntity.ok(stats);
    }

    @PostMapping("/update-all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, String>> triggerBulkAvailabilityUpdate() {
        log.info("Manually triggering bulk availability update");
        try {
            shopAvailabilityService.updateShopAvailability();
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Shop availability update completed successfully"
            ));
        } catch (Exception e) {
            log.error("Error during manual bulk availability update", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "error",
                "message", "Error updating shop availability: " + e.getMessage()
            ));
        }
    }
}