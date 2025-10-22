package com.shopmanagement.controller;

import com.shopmanagement.entity.Promotion;
import com.shopmanagement.entity.PromotionUsage;
import com.shopmanagement.repository.PromotionRepository;
import com.shopmanagement.service.PromotionService;
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

@RestController
@RequestMapping("/api/promotions")
@RequiredArgsConstructor
@Slf4j
public class PromotionController {

    private final PromotionRepository promotionRepository;
    private final PromotionService promotionService;

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
     */
    @GetMapping("/active")
    public ResponseEntity<Map<String, Object>> getActivePromotions(
            @RequestParam(required = false) Long shopId) {

        List<Promotion> promotions = promotionService.getActivePromotions(shopId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Active promotions retrieved successfully");
        response.put("data", promotions);
        response.put("count", promotions.size());

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
}