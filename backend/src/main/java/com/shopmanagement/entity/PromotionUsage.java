package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Tracks promotion usage by customers and devices
 * Prevents duplicate usage based on customer ID or device UUID
 */
@Entity
@Table(name = "promotion_usage",
       uniqueConstraints = {
           @UniqueConstraint(columnNames = {"promotion_id", "customer_id", "order_id"}),
           @UniqueConstraint(columnNames = {"promotion_id", "device_uuid", "order_id"})
       },
       indexes = {
           @Index(name = "idx_promotion_customer", columnList = "promotion_id,customer_id"),
           @Index(name = "idx_promotion_device", columnList = "promotion_id,device_uuid"),
           @Index(name = "idx_customer_usage", columnList = "customer_id,used_at")
       })
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class PromotionUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "promotion_id", nullable = false)
    private Promotion promotion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    private Order order;

    /**
     * Mobile device UUID for guest users or additional device tracking
     * Prevents same device from using promo code multiple times
     */
    @Column(name = "device_uuid", length = 100)
    private String deviceUuid;

    /**
     * Customer phone number for additional validation
     */
    @Column(name = "customer_phone", length = 15)
    private String customerPhone;

    /**
     * Customer email for additional validation
     */
    @Column(name = "customer_email", length = 100)
    private String customerEmail;

    /**
     * Discount amount applied from this promotion
     */
    @Column(name = "discount_applied", nullable = false, precision = 10, scale = 2)
    private BigDecimal discountApplied;

    /**
     * Original order amount before discount
     */
    @Column(name = "order_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal orderAmount;

    /**
     * Was this the customer's first order?
     */
    @Column(name = "is_first_order")
    @Builder.Default
    private Boolean isFirstOrder = false;

    /**
     * IP address for fraud detection
     */
    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    /**
     * User agent for device tracking
     */
    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @CreatedDate
    @Column(name = "used_at", nullable = false, updatable = false)
    private LocalDateTime usedAt;

    @Column(name = "shop_id")
    private Long shopId;

    /**
     * Additional notes or metadata
     */
    @Column(name = "notes", length = 500)
    private String notes;
}
