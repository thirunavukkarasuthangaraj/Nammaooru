package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Holds the withdrawable balance the platform owes to a shop or delivery partner for
 * online-paid orders (the platform holds the money via Razorpay until settlement).
 * COD orders never touch this — they settle through the existing PaymentSettlement flow,
 * where the driver already holds the cash and owes commission back to the platform.
 */
@Entity
@Table(name = "wallets", uniqueConstraints = {
        @UniqueConstraint(name = "uk_wallets_owner", columnNames = {"owner_type", "owner_id"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Wallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "owner_type", nullable = false, length = 20)
    private WalletOwnerType ownerType;

    /** shop_id when ownerType=SHOP, delivery-partner user_id when ownerType=DELIVERY_PARTNER */
    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(name = "total_earned", nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal totalEarned = BigDecimal.ZERO;

    @Column(name = "total_withdrawn", nullable = false, precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal totalWithdrawn = BigDecimal.ZERO;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String currency = "INR";

    // Payout destination — captured now, ready for whichever automated payout path
    // (Razorpay Route linked account / RazorpayX fund account) gets set up later.
    @Enumerated(EnumType.STRING)
    @Column(name = "payout_method", length = 20)
    private PayoutMethod payoutMethod;

    @Column(name = "bank_account_holder_name", length = 200)
    private String bankAccountHolderName;

    @Column(name = "bank_account_number", length = 50)
    private String bankAccountNumber;

    @Column(name = "bank_ifsc", length = 20)
    private String bankIfsc;

    @Column(name = "upi_id", length = 100)
    private String upiId;

    /** Null until a Razorpay Route linked account / RazorpayX fund account actually exists for this owner. */
    @Column(name = "razorpay_fund_account_id", length = 100)
    private String razorpayFundAccountId;

    @Column(name = "payout_details_verified", nullable = false)
    @Builder.Default
    private Boolean payoutDetailsVerified = false;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public enum WalletOwnerType {
        SHOP, DELIVERY_PARTNER
    }

    public enum PayoutMethod {
        BANK_ACCOUNT, UPI
    }
}
