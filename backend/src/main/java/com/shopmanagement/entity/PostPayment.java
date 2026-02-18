package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "post_payments")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostPayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "razorpay_order_id", nullable = false, length = 100)
    private String razorpayOrderId;

    @Column(name = "razorpay_payment_id", length = 100)
    private String razorpayPaymentId;

    @Column(name = "razorpay_signature", length = 255)
    private String razorpaySignature;

    @Column(nullable = false)
    private Integer amount;

    @Column(name = "processing_fee")
    @Builder.Default
    private Integer processingFee = 0;

    @Column(name = "total_amount")
    private Integer totalAmount;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String currency = "INR";

    @Column(name = "post_type", nullable = false, length = 50)
    private String postType;

    @Column(nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private PaymentStatus status = PaymentStatus.CREATED;

    @Column(nullable = false)
    @Builder.Default
    private Boolean consumed = false;

    @Column(name = "consumed_post_id")
    private Long consumedPostId;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "consumed_at")
    private LocalDateTime consumedAt;

    public enum PaymentStatus {
        CREATED,
        PAID,
        FAILED
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
