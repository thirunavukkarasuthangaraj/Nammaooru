package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * One row per WhatsApp message sent on behalf of a shop (POS bills etc).
 * Unsettled rows are charged on the shop's next pay-and-use payment.
 */
@Entity
@Table(name = "shop_whatsapp_usage")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopWhatsAppUsage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shop_id", nullable = false)
    private Long shopId;

    @Column(name = "message_type", nullable = false, length = 40)
    private String messageType;

    @Column(nullable = false)
    @Builder.Default
    private Boolean settled = false;

    @Column(name = "settled_payment_id")
    private Long settledPaymentId;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
