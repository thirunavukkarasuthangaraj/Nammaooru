package com.shopmanagement.controller;

import com.shopmanagement.entity.Promotion;
import com.shopmanagement.entity.PromotionUsage;
import com.shopmanagement.repository.PromotionRepository;
import com.shopmanagement.service.PromotionService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
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
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/promotions")
@RequiredArgsConstructor
@Slf4j
public class PromotionController {

    private final PromotionRepository promotionRepository;
    private final PromotionService promotionService;
    private final ShopRepository shopRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<Promotion>> getAllPromotions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        Page<Promotion> promotions = promotionRepository.findAll(pageable);
        return ResponseEntity.ok(promotions);
    }

    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getPromotionEnums() {
        return ResponseEntity.ok(Map.of(
                "promotionTypes", Promotion.PromotionType.values(),
                "promotionStatuses", Promotion.PromotionStatus.values()
        ));
    }

    /**
     * Validate promo code - PUBLIC API for customers
     * Can be used by both logged-in and guest users
     */
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validatePromoCode(@Valid @RequestBody PromoCodeValidationRequest request) {
        log.info("Validating promo code: {} for customer: {}, device: {}",
                request.getPromoCode(), request.getCustomerId(), request.getDeviceUuid());

        PromotionService.PromoCodeValidationResult result = promotionService.validatePromoCode(
                request.getPromoCode(),
                request.getCustomerId(),
                request.getDeviceUuid(),
                request.getPhone(),
                request.getOrderAmount(),
                request.getShopId()
        );

        Map<String, Object> response = new HashMap<>();
        response.put("valid", result.isValid());
        response.put("message", result.getMessage());

        if (result.isValid()) {
            response.put("discountAmount", result.getDiscountAmount());
            response.put("promotionId", result.getPromotion().getId());
            response.put("promotionTitle", result.getPromotion().getTitle());
            response.put("discountType", result.getPromotion().getType());
            response.put("statusCode", "0000");
            return ResponseEntity.ok(response);
        } else {
            response.put("statusCode", "1001");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }

    /**
     * Get active promotions - PUBLIC API
     * Returns promotions that customers can see and use
     * Filters out promotions that the user has already used (based on order history)
     *
     * @param shopId Shop ID for shop-specific promotions (optional)
     * @param customerId Customer ID (optional, for filtering used promos)
     * @param phone Customer phone (optional, for filtering used promos)
     */
    @GetMapping("/active")
    public ResponseEntity<Map<String, Object>> getActivePromotions(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Long customerId,
            @RequestParam(required = false) String phone) {

        log.debug("Fetching active promotions for shopId: {}, customerId: {}, phone: {}",
                shopId, customerId, phone);

        List<Promotion> promotions = promotionService.getActivePromotions(shopId, customerId, phone);

        // Enrich promotions with shop name
        List<Map<String, Object>> enrichedPromotions = promotions.stream()
            .map(promo -> {
                Map<String, Object> promoMap = new HashMap<>();
                promoMap.put("id", promo.getId());
                promoMap.put("code", promo.getCode());
                promoMap.put("title", promo.getTitle());
                promoMap.put("description", promo.getDescription());
                promoMap.put("type", promo.getType());
                promoMap.put("discountValue", promo.getDiscountValue());
                promoMap.put("minimumOrderAmount", promo.getMinimumOrderAmount());
                promoMap.put("maximumDiscountAmount", promo.getMaximumDiscountAmount());
                promoMap.put("usageLimitPerCustomer", promo.getUsageLimitPerCustomer());
                promoMap.put("startDate", promo.getStartDate());
                promoMap.put("endDate", promo.getEndDate());
                promoMap.put("imageUrl", promo.getImageUrl());
                promoMap.put("bannerUrl", promo.getBannerUrl());
                promoMap.put("isFirstTimeOnly", promo.getIsFirstTimeOnly());
                promoMap.put("termsAndConditions", promo.getTermsAndConditions());
                promoMap.put("shopId", promo.getShopId());

                // Get shop name if shopId exists
                if (promo.getShopId() != null) {
                    shopRepository.findById(promo.getShopId())
                        .ifPresent(shop -> {
                            promoMap.put("shopName", shop.getName());
                            promoMap.put("shopBusinessType", shop.getBusinessType());
                        });
                } else {
                    promoMap.put("shopName", "Platform Offer");
                }

                return promoMap;
            })
            .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Active promotions retrieved successfully");
        response.put("data", enrichedPromotions);
        response.put("count", enrichedPromotions.size());

        return ResponseEntity.ok(response);
    }

    /**
     * Get customer's promo code usage history
     */
    @GetMapping("/my-usage")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Map<String, Object>> getMyUsageHistory(
            @RequestParam Long customerId) {

        List<PromotionUsage> usages = promotionService.getCustomerUsageHistory(customerId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Usage history retrieved successfully");
        response.put("data", usages);
        response.put("count", usages.size());

        return ResponseEntity.ok(response);
    }

    /**
     * Get promotion statistics (Admin only)
     */
    @GetMapping("/{promotionId}/stats")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPromotionStats(@PathVariable Long promotionId) {
        Map<String, Object> stats = promotionService.getPromotionStats(promotionId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion statistics retrieved successfully");
        response.put("data", stats);

        return ResponseEntity.ok(response);
    }

    /**
     * Get promotion by ID (Admin only)
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPromotionById(@PathVariable Long id) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion retrieved successfully");
        response.put("data", promotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Create new promotion (Admin only)
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> createPromotion(@Valid @RequestBody CreatePromotionRequest request) {
        log.info("Creating new promotion: {}", request.getCode());

        Promotion promotion = new Promotion();
        promotion.setCode(request.getCode().toUpperCase());
        promotion.setTitle(request.getTitle());
        promotion.setDescription(request.getDescription());
        promotion.setType(Promotion.PromotionType.valueOf(request.getType()));
        promotion.setDiscountValue(request.getDiscountValue());
        promotion.setMinimumOrderAmount(request.getMinimumOrderAmount());
        promotion.setMaximumDiscountAmount(request.getMaximumDiscountAmount());
        promotion.setStartDate(request.getStartDate());
        promotion.setEndDate(request.getEndDate());
        promotion.setStatus(Promotion.PromotionStatus.valueOf(request.getStatus()));
        promotion.setUsageLimit(request.getUsageLimit());
        promotion.setUsageLimitPerCustomer(request.getUsageLimitPerCustomer());
        promotion.setIsFirstTimeOnly(request.isFirstTimeOnly());
        promotion.setIsPublic(request.isApplicableToAllShops());
        promotion.setImageUrl(request.getImageUrl());

        Promotion savedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion created successfully");
        response.put("data", savedPromotion);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Update existing promotion (Admin only)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> updatePromotion(
            @PathVariable Long id,
            @Valid @RequestBody CreatePromotionRequest request) {
        log.info("Updating promotion: {}", id);

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        // Update fields - code cannot be changed
        promotion.setTitle(request.getTitle());
        promotion.setDescription(request.getDescription());
        promotion.setType(Promotion.PromotionType.valueOf(request.getType()));
        promotion.setDiscountValue(request.getDiscountValue());
        promotion.setMinimumOrderAmount(request.getMinimumOrderAmount());
        promotion.setMaximumDiscountAmount(request.getMaximumDiscountAmount());
        promotion.setStartDate(request.getStartDate());
        promotion.setEndDate(request.getEndDate());
        promotion.setStatus(Promotion.PromotionStatus.valueOf(request.getStatus()));
        promotion.setUsageLimit(request.getUsageLimit());
        promotion.setUsageLimitPerCustomer(request.getUsageLimitPerCustomer());
        promotion.setIsFirstTimeOnly(request.isFirstTimeOnly());
        promotion.setIsPublic(request.isApplicableToAllShops());
        promotion.setImageUrl(request.getImageUrl());

        Promotion updatedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion updated successfully");
        response.put("data", updatedPromotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Delete promotion (Admin only)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> deletePromotion(@PathVariable Long id) {
        log.info("Deleting promotion: {}", id);

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        promotionRepository.delete(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion deleted successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Activate promotion (Admin only)
     */
    @PatchMapping("/{id}/activate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> activatePromotion(@PathVariable Long id) {
        log.info("Activating promotion: {}", id);

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        promotion.setStatus(Promotion.PromotionStatus.ACTIVE);
        Promotion updatedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion activated successfully");
        response.put("data", updatedPromotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Deactivate promotion (Admin only)
     */
    @PatchMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> deactivatePromotion(@PathVariable Long id) {
        log.info("Deactivating promotion: {}", id);

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found with id: " + id));

        promotion.setStatus(Promotion.PromotionStatus.INACTIVE);
        Promotion updatedPromotion = promotionRepository.save(promotion);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Promotion deactivated successfully");
        response.put("data", updatedPromotion);

        return ResponseEntity.ok(response);
    }

    /**
     * Get promotion usage history with pagination (Admin only)
     */
    @GetMapping("/{promotionId}/usage")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPromotionUsageHistory(
            @PathVariable Long promotionId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "usedAt"));
        Page<PromotionUsage> usages = promotionService.getPromotionUsageHistory(promotionId, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Usage history retrieved successfully");
        response.put("data", Map.of(
                "content", usages.getContent(),
                "totalElements", usages.getTotalElements(),
                "totalPages", usages.getTotalPages()
        ));

        return ResponseEntity.ok(response);
    }

    /**
     * Request DTO for promo code validation
     */
    @Data
    public static class PromoCodeValidationRequest {

        @NotBlank(message = "Promo code is required")
        @Size(max = 50, message = "Promo code cannot exceed 50 characters")
        private String promoCode;

        // Customer ID (optional - for registered users)
        private Long customerId;

        // Device UUID (required for guests, optional for registered users)
        @Size(max = 100, message = "Device UUID cannot exceed 100 characters")
        private String deviceUuid;

        // Phone number (fallback identifier)
        @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid phone number")
        private String phone;

        @NotNull(message = "Order amount is required")
        @DecimalMin(value = "0.0", message = "Order amount must be positive")
        private BigDecimal orderAmount;

        // Shop ID (for shop-specific promotions)
        private Long shopId;
    }

    /**
     * Request DTO for creating/updating promotions
     */
    @Data
    public static class CreatePromotionRequest {
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
        private String type; // PERCENTAGE, FIXED_AMOUNT, FREE_SHIPPING

        @NotNull(message = "Discount value is required")
        @DecimalMin(value = "0.0", message = "Discount value must be positive")
        private BigDecimal discountValue;

        @DecimalMin(value = "0.0", message = "Minimum order amount must be positive")
        private BigDecimal minimumOrderAmount;

        private BigDecimal maximumDiscountAmount;

        @NotNull(message = "Start date is required")
        private java.time.LocalDateTime startDate;

        @NotNull(message = "End date is required")
        private java.time.LocalDateTime endDate;

        @NotBlank(message = "Status is required")
        private String status; // ACTIVE, INACTIVE

        private Integer usageLimit;

        private Integer usageLimitPerCustomer;

        private boolean firstTimeOnly;

        private boolean applicableToAllShops = true;

        private String imageUrl;
    }
}