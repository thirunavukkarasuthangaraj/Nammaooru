package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "shop_payment_collections")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopPaymentCollection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shop_id", nullable = false)
    private Long shopId;

    @Column(nullable = false)
    private Integer amount;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String currency = "INR";

    @Column(name = "razorpay_order_id", nullable = false, length = 100)
    private String razorpayOrderId;

    @Column(name = "razorpay_payment_id", length = 100)
    private String razorpayPaymentId;

    @Column(name = "razorpay_signature", length = 255)
    private String razorpaySignature;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private CollectionStatus status = CollectionStatus.CREATED;

    // WhatsApp usage charged with this payment (count + paise); amount stays platform fee in rupees
    @Column(name = "usage_count", nullable = false)
    @Builder.Default
    private Integer usageCount = 0;

    @Column(name = "usage_amount", nullable = false)
    @Builder.Default
    private Integer usageAmount = 0;

    @Column(name = "gst_amount", nullable = false)
    @Builder.Default
    private Integer gstAmount = 0;

    @Column(name = "valid_until")
    private LocalDateTime validUntil;

    // Exact instant the usage count/charge on this invoice was computed at order-creation time.
    // verifyPayment settles messages up to this same instant so a message sent mid-checkout
    // can never be both charged on this invoice AND left unsettled for the next one (or vice versa).
    @Column(name = "usage_cutoff")
    private LocalDateTime usageCutoff;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    public enum CollectionStatus {
        CREATED,
        PAID,
        FAILED
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
