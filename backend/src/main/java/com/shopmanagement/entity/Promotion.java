package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "promotions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Promotion {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 200)
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(unique = true, nullable = false, length = 50)
    private String code;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PromotionType type;
    
    @Column(name = "discount_value", nullable = false)
    private BigDecimal discountValue;
    
    @Column(name = "minimum_order_amount")
    private BigDecimal minimumOrderAmount;
    
    @Column(name = "maximum_discount_amount")
    private BigDecimal maximumDiscountAmount;
    
    @Column(name = "usage_limit")
    private Integer usageLimit;
    
    @Column(name = "usage_limit_per_customer")
    private Integer usageLimitPerCustomer;
    
    @Column(name = "used_count")
    @Builder.Default
    private Integer usedCount = 0;
    
    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;
    
    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private PromotionStatus status = PromotionStatus.ACTIVE;
    
    @Column(name = "shop_id")
    private Long shopId;
    
    @Column(name = "target_audience", length = 50)
    private String targetAudience;
    
    @Column(name = "terms_and_conditions", columnDefinition = "TEXT")
    private String termsAndConditions;
    
    @Builder.Default
    private Boolean isPublic = true;
    
    @Builder.Default
    private Boolean isFirstTimeOnly = false;
    
    @Builder.Default
    private Boolean stackable = false;
    
    @Column(name = "image_url")
    private String imageUrl;
    
    @Column(name = "banner_url")
    private String bannerUrl;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "created_by", length = 100)
    private String createdBy;
    
    @Column(name = "updated_by", length = 100)
    private String updatedBy;
    
    // Helper methods
    public boolean isActive() {
        LocalDateTime now = LocalDateTime.now();
        return status == PromotionStatus.ACTIVE && 
               startDate.isBefore(now) && 
               endDate.isAfter(now) &&
               (usageLimit == null || usedCount < usageLimit);
    }
    
    public boolean canBeUsed() {
        return isActive() && status == PromotionStatus.ACTIVE;
    }
    
    public boolean hasUsageLeft() {
        return usageLimit == null || usedCount < usageLimit;
    }
    
    public BigDecimal calculateDiscount(BigDecimal orderAmount) {
        if (!canBeUsed() || orderAmount.compareTo(minimumOrderAmount != null ? minimumOrderAmount : BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal discount;
        if (type == PromotionType.PERCENTAGE) {
            discount = orderAmount.multiply(discountValue).divide(BigDecimal.valueOf(100));
        } else {
            discount = discountValue;
        }
        
        if (maximumDiscountAmount != null && discount.compareTo(maximumDiscountAmount) > 0) {
            discount = maximumDiscountAmount;
        }
        
        return discount;
    }
    
    public enum PromotionType {
        PERCENTAGE, FIXED_AMOUNT, FREE_SHIPPING, BUY_ONE_GET_ONE
    }
    
    public enum PromotionStatus {
        ACTIVE, INACTIVE, EXPIRED, SUSPENDED
    }
}