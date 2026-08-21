package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * One row per message a customer sends to the business WhatsApp number
 * (received via the Meta Cloud API webhook). Staff process NEW rows from
 * the admin WhatsApp inbox and convert them into POS bills.
 */
@Entity
@Table(name = "whatsapp_incoming_messages")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WhatsAppIncomingMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Meta's unique message id (wamid...); used to dedupe webhook retries. */
    @Column(name = "wa_message_id", nullable = false, unique = true, length = 128)
    private String waMessageId;

    @Column(name = "from_number", nullable = false, length = 20)
    private String fromNumber;

    /** The customer's WhatsApp profile name (as they set it, may be null). */
    @Column(name = "profile_name", length = 120)
    private String profileName;

    /** text, image, audio, interactive, order, ... (Meta message type) */
    @Column(name = "message_type", nullable = false, length = 30)
    private String messageType;

    @Column(columnDefinition = "TEXT")
    private String body;

    /** NEW -> PROCESSED (staff handled it) */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "NEW";

    @Column(name = "auto_replied", nullable = false)
    @Builder.Default
    private Boolean autoReplied = false;

    /** Timestamp from the Meta payload (when the customer sent it). */
    @Column(name = "received_at")
    private LocalDateTime receivedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
