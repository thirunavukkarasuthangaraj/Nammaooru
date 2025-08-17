package com.shopmanagement.delivery.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "partner_earnings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartnerEarning {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private DeliveryPartner deliveryPartner;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id", nullable = false)
    private OrderAssignment orderAssignment;

    @Column(name = "base_amount", precision = 10, scale = 2, nullable = false)
    private BigDecimal baseAmount;

    @Column(name = "incentive_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal incentiveAmount = BigDecimal.ZERO;

    @Column(name = "bonus_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal bonusAmount = BigDecimal.ZERO;

    @Column(name = "penalty_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal penaltyAmount = BigDecimal.ZERO;

    @Column(name = "total_amount", precision = 10, scale = 2, nullable = false)
    private BigDecimal totalAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", length = 20)
    @Builder.Default
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    @Column(name = "payment_date")
    private LocalDateTime paymentDate;

    @Column(name = "payment_reference", length = 100)
    private String paymentReference;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 20)
    private PaymentMethod paymentMethod;

    @Column(name = "distance_covered", precision = 8, scale = 2)
    private BigDecimal distanceCovered;

    @Column(name = "time_taken")
    private Integer timeTaken;

    @Column(name = "surge_multiplier", precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal surgeMultiplier = BigDecimal.ONE;

    @Column(name = "earning_date")
    @Builder.Default
    private LocalDate earningDate = LocalDate.now();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    private void calculateTotalAmount() {
        totalAmount = baseAmount
                .add(incentiveAmount)
                .add(bonusAmount)
                .subtract(penaltyAmount);
    }

    public boolean isPaid() {
        return paymentStatus == PaymentStatus.PAID;
    }

    public boolean canBeProcessed() {
        return paymentStatus == PaymentStatus.PENDING;
    }

    public enum PaymentStatus {
        PENDING, PROCESSED, PAID, FAILED, HOLD
    }

    public enum PaymentMethod {
        BANK_TRANSFER, UPI, CASH, WALLET
    }
}