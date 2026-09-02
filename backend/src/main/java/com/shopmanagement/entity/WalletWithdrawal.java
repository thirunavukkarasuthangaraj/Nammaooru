package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * A withdrawal request's lifecycle (PENDING -> PAID/REJECTED). Only once it's marked PAID
 * does a WalletTransaction DEBIT get written — the ledger never carries a pending entry.
 * payoutReference holds the manual bank transfer UTR today; once RazorpayX payouts are
 * wired up it becomes the RazorpayX payout id instead, with no schema change needed.
 */
@Entity
@Table(name = "wallet_withdrawals")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WalletWithdrawal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wallet_id", nullable = false)
    private Wallet wallet;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private WithdrawalStatus status = WithdrawalStatus.PENDING;

    @Column(name = "payout_reference", length = 200)
    private String payoutReference;

    @Column(length = 500)
    private String notes;

    @Column(name = "requested_at", nullable = false)
    @Builder.Default
    private LocalDateTime requestedAt = LocalDateTime.now();

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    @Column(name = "processed_by", length = 100)
    private String processedBy;

    public enum WithdrawalStatus {
        PENDING, PAID, REJECTED
    }
}
