package com.shopmanagement.service;

import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.Promotion;
import com.shopmanagement.entity.PromotionUsage;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.PromotionRepository;
import com.shopmanagement.repository.PromotionUsageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class PromotionService {

    private final PromotionRepository promotionRepository;
    private final PromotionUsageRepository promotionUsageRepository;
    private final CustomerRepository customerRepository;

    /**
     * Validate if a promo code can be used by a customer
     *
     * @param promoCode The promotion code to validate
     * @param customerId Customer ID (can be null for guest)
     * @param deviceUuid Mobile device UUID
     * @param phone Customer phone number
     * @param orderAmount Order amount before discount
     * @param shopId Shop ID for shop-specific promotions
     * @return Validation result with discount amount or error message
     */
    @Transactional(readOnly = true)
    public PromoCodeValidationResult validatePromoCode(
            String promoCode,
            Long customerId,
            String deviceUuid,
            String phone,
            BigDecimal orderAmount,
            Long shopId) {

        log.info("Validating promo code: {} for customer: {}, device: {}, phone: {}",
                promoCode, customerId, deviceUuid, phone);

        // 1. Find promotion by code
        Optional<Promotion> promotionOpt = promotionRepository.findByCode(promoCode);
        if (promotionOpt.isEmpty()) {
            return PromoCodeValidationResult.error("Invalid promo code");
        }

        Promotion promotion = promotionOpt.get();

        // 2. Check if promotion is active
        if (!promotion.isActive()) {
            return PromoCodeValidationResult.error("This promo code has expired or is no longer active");
        }

        // 3. Check date validity
        LocalDateTime now = LocalDateTime.now();
        if (promotion.getStartDate().isAfter(now)) {
            return PromoCodeValidationResult.error("This promo code is not yet valid");
        }
        if (promotion.getEndDate().isBefore(now)) {
            return PromoCodeValidationResult.error("This promo code has expired");
        }

        // 4. Check minimum order amount
        if (promotion.getMinimumOrderAmount() != null &&
            orderAmount.compareTo(promotion.getMinimumOrderAmount()) < 0) {
            return PromoCodeValidationResult.error(
                String.format("Minimum order amount of ₹%.2f required",
                    promotion.getMinimumOrderAmount())
            );
        }

        // 5. Check shop-specific promotion
        if (promotion.getShopId() != null && !promotion.getShopId().equals(shopId)) {
            return PromoCodeValidationResult.error("This promo code is not valid for this shop");
        }

        // 6. Check total usage limit
        if (promotion.getUsageLimit() != null &&
            promotion.getUsedCount() >= promotion.getUsageLimit()) {
            return PromoCodeValidationResult.error("This promo code has reached its usage limit");
        }

        // 7. Check first-time-only restriction
        if (promotion.getIsFirstTimeOnly()) {
            Boolean isFirstTime = promotionUsageRepository.isFirstTimeCustomer(customerId);
            if (!isFirstTime) {
                return PromoCodeValidationResult.error("This promo code is only for first-time customers");
            }
        }

        // 8. Check per-customer usage limit (tracks by customer ID, device UUID, or phone)
        if (promotion.getUsageLimitPerCustomer() != null) {
            Long usageCount;

            if (customerId != null) {
                // Registered customer: check by customer ID
                usageCount = promotionUsageRepository.countByPromotionIdAndCustomerId(
                    promotion.getId(), customerId);
            } else if (deviceUuid != null) {
                // Guest user: check by device UUID
                usageCount = promotionUsageRepository.countByPromotionIdAndDeviceUuid(
                    promotion.getId(), deviceUuid);
            } else if (phone != null) {
                // Fallback: check by phone number
                usageCount = promotionUsageRepository.countByPromotionIdAndPhone(
                    promotion.getId(), phone);
            } else {
                return PromoCodeValidationResult.error("Unable to validate promo code usage");
            }

            if (usageCount >= promotion.getUsageLimitPerCustomer()) {
                return PromoCodeValidationResult.error(
                    String.format("You have already used this promo code %d time(s). Maximum allowed: %d",
                        usageCount, promotion.getUsageLimitPerCustomer())
                );
            }
        }

        // 9. Additional check: Prevent abuse by checking ALL identifiers
        // If any identifier (customer ID, device UUID, phone) matches previous usage beyond limit
        if (customerId != null && deviceUuid != null && phone != null &&
            promotion.getUsageLimitPerCustomer() != null) {
            Long totalUsage = promotionUsageRepository.countByPromotionAndAnyIdentifier(
                promotion.getId(), customerId, deviceUuid, phone);

            if (totalUsage >= promotion.getUsageLimitPerCustomer()) {
                return PromoCodeValidationResult.error("This device or account has already used this promo code");
            }
        }

        // 10. Calculate discount
        BigDecimal discountAmount = promotion.calculateDiscount(orderAmount);

        // 11. All validations passed
        return PromoCodeValidationResult.success(
            promotion,
            discountAmount,
            "Promo code applied successfully!"
        );
    }

    /**
     * Record promotion usage after order is placed
     */
    @Transactional
    public void recordPromotionUsage(
            Promotion promotion,
            Customer customer,
            Order order,
            String deviceUuid,
            String phone,
            String email,
            BigDecimal discountApplied,
            BigDecimal orderAmount,
            Boolean isFirstOrder,
            String ipAddress,
            String userAgent) {

        PromotionUsage usage = PromotionUsage.builder()
                .promotion(promotion)
                .customer(customer)
                .order(order)
                .deviceUuid(deviceUuid)
                .customerPhone(phone)
                .customerEmail(email)
                .discountApplied(discountApplied)
                .orderAmount(orderAmount)
                .isFirstOrder(isFirstOrder)
                .ipAddress(ipAddress)
                .userAgent(userAgent)
                .shopId(order.getShop().getId())
                .build();

        promotionUsageRepository.save(usage);

        // Increment used count
        promotion.setUsedCount(promotion.getUsedCount() + 1);
        promotionRepository.save(promotion);

        log.info("Recorded promotion usage: code={}, customer={}, device={}, discount={}",
                promotion.getCode(), customer != null ? customer.getId() : "guest",
                deviceUuid, discountApplied);
    }

    /**
     * Get all active promotions visible to customers
     */
    @Transactional(readOnly = true)
    public List<Promotion> getActivePromotions(Long shopId) {
        if (shopId != null) {
            return promotionRepository.findActiveByShopId(shopId, LocalDateTime.now());
        }
        return promotionRepository.findAllPublicActive(LocalDateTime.now());
    }

    /**
     * Get customer's promotion usage history
     */
    @Transactional(readOnly = true)
    public List<PromotionUsage> getCustomerUsageHistory(Long customerId) {
        return promotionUsageRepository.findByCustomerId(customerId);
    }

    /**
     * Get promotion usage statistics
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getPromotionStats(Long promotionId) {
        List<PromotionUsage> usages = promotionUsageRepository.findByPromotionId(promotionId);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsageCount", usages.size());
        stats.put("uniqueCustomers", usages.stream()
                .filter(u -> u.getCustomer() != null)
                .map(u -> u.getCustomer().getId())
                .distinct()
                .count());
        stats.put("uniqueDevices", usages.stream()
                .filter(u -> u.getDeviceUuid() != null)
                .map(PromotionUsage::getDeviceUuid)
                .distinct()
                .count());
        stats.put("totalDiscountGiven", usages.stream()
                .map(PromotionUsage::getDiscountApplied)
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        stats.put("recentUsages", usages.stream().limit(10).toList());

        return stats;
    }

    /**
     * Result class for promo code validation
     */
    public static class PromoCodeValidationResult {
        private final boolean valid;
        private final String message;
        private final Promotion promotion;
        private final BigDecimal discountAmount;

        private PromoCodeValidationResult(boolean valid, String message,
                                         Promotion promotion, BigDecimal discountAmount) {
            this.valid = valid;
            this.message = message;
            this.promotion = promotion;
            this.discountAmount = discountAmount;
        }

        public static PromoCodeValidationResult success(Promotion promotion,
                                                       BigDecimal discountAmount,
                                                       String message) {
            return new PromoCodeValidationResult(true, message, promotion, discountAmount);
        }

        public static PromoCodeValidationResult error(String message) {
            return new PromoCodeValidationResult(false, message, null, BigDecimal.ZERO);
        }

        // Getters
        public boolean isValid() { return valid; }
        public String getMessage() { return message; }
        public Promotion getPromotion() { return promotion; }
        public BigDecimal getDiscountAmount() { return discountAmount; }
    }
}
