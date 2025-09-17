package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "delivery_partner_earnings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryPartnerEarnings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_partner_id", nullable = false)
    private User deliveryPartner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "earning_date", nullable = false)
    private LocalDate earningDate;

    @Column(name = "delivery_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @Column(name = "commission_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal commissionRate; // e.g., 0.8000 for 80%

    @Column(name = "commission_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal commissionAmount; // Partner's earning

    @Column(name = "platform_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal platformFee; // Platform's cut

    @Column(name = "bonus_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal bonusAmount = BigDecimal.ZERO;

    @Column(name = "penalty_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal penaltyAmount = BigDecimal.ZERO;

    @Column(name = "net_earning", nullable = false, precision = 10, scale = 2)
    private BigDecimal netEarning; // commission + bonus - penalty

    @Column(name = "tax_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal taxAmount = BigDecimal.ZERO;

    @Column(name = "final_earning", nullable = false, precision = 10, scale = 2)
    private BigDecimal finalEarning; // net_earning - tax

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false)
    @Builder.Default
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    @Column(name = "payment_date")
    private LocalDateTime paymentDate;

    @Column(name = "payment_reference", length = 100)
    private String paymentReference;

    // Performance metrics
    @Column(name = "delivery_time_minutes")
    private Integer deliveryTimeMinutes;

    @Column(name = "distance_km", precision = 8, scale = 2)
    private BigDecimal distanceKm;

    @Column(name = "customer_rating", precision = 3, scale = 2)
    private BigDecimal customerRating;

    @Column(name = "delivery_notes", length = 500)
    private String deliveryNotes;

    // Audit fields
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "created_by", nullable = false, length = 100)
    @Builder.Default
    private String createdBy = "system";

    @Column(name = "updated_by", nullable = false, length = 100)
    @Builder.Default
    private String updatedBy = "system";

    // Helper methods for calculations
    public void calculateEarnings() {
        // Calculate commission amount
        this.commissionAmount = this.deliveryFee.multiply(this.commissionRate);

        // Calculate platform fee
        this.platformFee = this.deliveryFee.subtract(this.commissionAmount);

        // Calculate net earning
        this.netEarning = this.commissionAmount
            .add(this.bonusAmount != null ? this.bonusAmount : BigDecimal.ZERO)
            .subtract(this.penaltyAmount != null ? this.penaltyAmount : BigDecimal.ZERO);

        // Calculate final earning
        this.finalEarning = this.netEarning
            .subtract(this.taxAmount != null ? this.taxAmount : BigDecimal.ZERO);
    }

    public enum PaymentStatus {
        PENDING,
        PROCESSING,
        PAID,
        FAILED,
        CANCELLED
    }
}