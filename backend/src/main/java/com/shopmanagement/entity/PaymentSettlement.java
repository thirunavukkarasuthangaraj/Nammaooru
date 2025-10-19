package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payment_settlements")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentSettlement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private User deliveryPartner;

    @Column(name = "settlement_date", nullable = false)
    private LocalDateTime settlementDate;

    @Column(name = "cash_collected", nullable = false, precision = 10, scale = 2)
    private BigDecimal cashCollected;

    @Column(name = "commission_earned", nullable = false, precision = 10, scale = 2)
    private BigDecimal commissionEarned;

    @Column(name = "net_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal netAmount;

    @Column(name = "total_orders", nullable = false)
    private Integer totalOrders;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 50)
    private PaymentMethod paymentMethod;

    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "settled_by")
    private String settledBy; // Admin username who settled

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private SettlementStatus status = SettlementStatus.COMPLETED;

    // Payment methods enum
    public enum PaymentMethod {
        CASH,
        UPI,
        BANK_TRANSFER,
        CHEQUE,
        OTHER
    }

    // Settlement status enum
    public enum SettlementStatus {
        PENDING,
        COMPLETED,
        CANCELLED,
        DISPUTED
    }
}
