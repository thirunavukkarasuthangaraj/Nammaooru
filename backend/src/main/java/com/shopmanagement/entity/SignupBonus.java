package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * One-time welcome bonus queued for manual UPI payout to a newly registered
 * customer's mobile number. See V119__create_signup_bonuses_table.sql for
 * why this is separate from the shop/delivery-partner Wallet system.
 */
@Entity
@Table(name = "signup_bonuses")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SignupBonus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "mobile_number", nullable = false, unique = true, length = 20)
    private String mobileNumber;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Status status = Status.UNPAID;

    @Column(name = "payout_reference", length = 100)
    private String payoutReference;

    @Column(name = "processed_by", length = 100)
    private String processedBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    public enum Status {
        UNPAID, PAID
    }
}
