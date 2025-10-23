package com.shopmanagement.controller;

import com.shopmanagement.entity.Promotion;
import com.shopmanagement.entity.PromotionUsage;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.repository.PromotionRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.service.PromotionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shop-owner/promotions")
@RequiredArgsConstructor
@Slf4j
public class ShopOwnerPromotionController {

    private final PromotionRepository promotionRepository;
    private final ShopRepository shopRepository;
    private final PromotionService promotionService;

    /**
     * Get all promotions for the shop owner's shop
     */
    @GetMapping
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getMyShopPromotions(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));

        Page<Promotion> promotions = promotionRepository.findByShopId(shop.getId(), pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Shop promotions retrieved successfully");
        response.put("data", Map.of(
                "content", promotions.getContent(),
                "totalElements", promotions.getTotalElements(),
                "totalPages", promotions.getTotalPages(),
                "currentPage", promotions.getNumber()
        ));

        return ResponseEntity.ok(response);
    }

    /**
     * Create new promotion for shop owner's shop
     */
    @PostMapping
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> createShopPromotion(
            Authentication authentication,
            @Valid @RequestBody CreateShopPromotionRequest request) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        log.info("Creating new shop promotion: {} for shop: {}", request.getCode(), shop.getName());

        // Check if code already exists
        if (promotionRepository.findByCode(request.getCode().toUpperCase()).isPresent()) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1002");
            errorResponse.put("message", "Promo code already exists");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        }

        Promotion promotion = Promotion.builder()
                .code(request.getCode().toUpperCase())
                .title(request.getTitle())
                .description(request.getDescription())
                .type(Promotion.PromotionType.valueOf(request.getType()))
                .discountValue(request.getDiscountValue())
                .minimumOrderAmount(request.getMinimumOrderAmount())
                .maximumDiscountAmount(request.getMaximumDiscountAmount())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(Promotion.PromotionStatus.ACTIVE)
                .usageLimit(request.getUsageLimit())
                .usageLimitPerCustomer(request.getUsageLimitPerCustomer())
                .isFirstTimeOnly(request.isFirstTimeOnly())
                .isPublic(true)
                .shopId(shop.getId())  // Set shop ID so promo is shop-specific
                .createdBy(email)
                .usedCount(0)
                .build();

        Promotion savedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Shop promotion created successfully");
        response.put("data", savedPromotion);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Update shop owner's promotion
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> updateShopPromotion(
            Authentication authentication,
            @PathVariable Long id,
            @Valid @RequestBody CreateShopPromotionRequest request) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        log.info("Updating shop promotion: {} for shop: {}", id, shop.getName());

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Verify promotion belongs to this shop
        if (!promotion.getShopId().equals(shop.getId())) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1003");
            errorResponse.put("message", "You can only update promotions for your own shop");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        // Update fields (code cannot be changed)
        promotion.setTitle(request.getTitle());
        promotion.setDescription(request.getDescription());
        promotion.setType(Promotion.PromotionType.valueOf(request.getType()));
        promotion.setDiscountValue(request.getDiscountValue());
        promotion.setMinimumOrderAmount(request.getMinimumOrderAmount());
        promotion.setMaximumDiscountAmount(request.getMaximumDiscountAmount());
        promotion.setStartDate(request.getStartDate());
        promotion.setEndDate(request.getEndDate());
        promotion.setUsageLimit(request.getUsageLimit());
        promotion.setUsageLimitPerCustomer(request.getUsageLimitPerCustomer());
        promotion.setIsFirstTimeOnly(request.isFirstTimeOnly());
        promotion.setUpdatedBy(email);

        Promotion updatedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Shop promotion updated successfully");
        response.put("data", updatedPromotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Delete shop owner's promotion
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> deleteShopPromotion(
            Authentication authentication,
            @PathVariable Long id) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        log.info("Deleting shop promotion: {} for shop: {}", id, shop.getName());

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Verify promotion belongs to this shop
        if (!promotion.getShopId().equals(shop.getId())) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1003");
            errorResponse.put("message", "You can only delete promotions for your own shop");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        promotionRepository.delete(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Shop promotion deleted successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Activate/Deactivate shop owner's promotion
     */
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> togglePromotionStatus(
            Authentication authentication,
            @PathVariable Long id,
            @RequestParam String status) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        log.info("Toggling promotion status: {} to {} for shop: {}", id, status, shop.getName());

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Verify promotion belongs to this shop
        if (!promotion.getShopId().equals(shop.getId())) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1003");
            errorResponse.put("message", "You can only modify promotions for your own shop");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        promotion.setStatus(Promotion.PromotionStatus.valueOf(status.toUpperCase()));
        Promotion updatedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion status updated successfully");
        response.put("data", updatedPromotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Get promotion statistics for shop owner
     */
    @GetMapping("/{id}/stats")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getPromotionStats(
            Authentication authentication,
            @PathVariable Long id) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Verify promotion belongs to this shop
        if (!promotion.getShopId().equals(shop.getId())) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1003");
            errorResponse.put("message", "You can only view statistics for your own shop's promotions");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        Map<String, Object> stats = promotionService.getPromotionStats(id);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion statistics retrieved successfully");
        response.put("data", stats);

        return ResponseEntity.ok(response);
    }

    /**
     * Get promotion usage history
     */
    @GetMapping("/{id}/usage")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getPromotionUsage(
            Authentication authentication,
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        // Get shop owner's shop
        String email = authentication.getName();
        Shop shop = shopRepository.findByOwnerEmail(email)
                .orElseThrow(() -> new RuntimeException("Shop not found for owner: " + email));

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Verify promotion belongs to this shop
        if (!promotion.getShopId().equals(shop.getId())) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("statusCode", "1003");
            errorResponse.put("message", "You can only view usage for your own shop's promotions");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "usedAt"));
        Page<PromotionUsage> usages = promotionService.getPromotionUsageHistory(id, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Usage history retrieved successfully");
        response.put("data", Map.of(
                "content", usages.getContent(),
                "totalElements", usages.getTotalElements(),
                "totalPages", usages.getTotalPages(),
                "currentPage", usages.getNumber()
        ));

        return ResponseEntity.ok(response);
    }

    /**
     * Request DTO for creating/updating shop promotions
     */
    @Data
    public static class CreateShopPromotionRequest {
        @NotBlank(message = "Code is required")
        @Size(min = 4, max = 20, message = "Code must be between 4 and 20 characters")
        @Pattern(regexp = "^[A-Z0-9]+$", message = "Code must contain only uppercase letters and numbers")
        private String code;

        @NotBlank(message = "Title is required")
        @Size(max = 100, message = "Title cannot exceed 100 characters")
        private String title;

        @Size(max = 500, message = "Description cannot exceed 500 characters")
        private String description;

        @NotBlank(message = "Type is required")
        private String type; // PERCENTAGE, FIXED_AMOUNT

        @NotNull(message = "Discount value is required")
        @DecimalMin(value = "0.0", inclusive = false, message = "Discount value must be greater than 0")
        private BigDecimal discountValue;

        @DecimalMin(value = "0.0", message = "Minimum order amount must be positive")
        private BigDecimal minimumOrderAmount;

        private BigDecimal maximumDiscountAmount;

        @NotNull(message = "Start date is required")
        private LocalDateTime startDate;

        @NotNull(message = "End date is required")
        private LocalDateTime endDate;

        private Integer usageLimit;

        private Integer usageLimitPerCustomer;

        private boolean firstTimeOnly = false;
    }
}
