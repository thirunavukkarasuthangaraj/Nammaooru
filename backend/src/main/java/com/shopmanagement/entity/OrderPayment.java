package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Tracks a Razorpay payment against an Order: the Razorpay order/payment/refund IDs,
 * and the fee breakdown. {@code orderAmount} is what the shop/driver are owed (Order's
 * own totalAmount); {@code gatewayFeeAmount} is Razorpay's cut, added on top and charged
 * to the customer so neither the shop nor the platform absorbs it; {@code totalChargedAmount}
 * is what actually gets charged via Razorpay Checkout.
 */
@Entity
@Table(name = "order_payments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderPayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @Column(name = "razorpay_order_id", nullable = false, unique = true, length = 100)
    private String razorpayOrderId;

    @Column(name = "razorpay_payment_id", length = 100)
    private String razorpayPaymentId;

    @Column(name = "razorpay_signature", length = 200)
    private String razorpaySignature;

    @Column(name = "order_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal orderAmount;

    @Column(name = "gateway_fee_amount", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal gatewayFeeAmount = BigDecimal.ZERO;

    @Column(name = "total_charged_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalChargedAmount;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String currency = "INR";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private OrderPaymentStatus status = OrderPaymentStatus.CREATED;

    @Column(name = "razorpay_refund_id", length = 100)
    private String razorpayRefundId;

    @Column(name = "refund_amount", precision = 10, scale = 2)
    private BigDecimal refundAmount;

    @Column(name = "refund_fee_amount", precision = 10, scale = 2)
    private BigDecimal refundFeeAmount;

    @Column(name = "failure_reason", length = 500)
    private String failureReason;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public enum OrderPaymentStatus {
        CREATED, PAID, FAILED, REFUNDED, PARTIALLY_REFUNDED
    }
}
