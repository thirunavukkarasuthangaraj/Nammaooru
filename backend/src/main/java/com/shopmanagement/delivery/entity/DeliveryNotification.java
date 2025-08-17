package com.shopmanagement.delivery.entity;

import com.shopmanagement.entity.Customer;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "delivery_notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id", nullable = false)
    private OrderAssignment orderAssignment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private DeliveryPartner deliveryPartner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Enumerated(EnumType.STRING)
    @Column(name = "notification_type", nullable = false, length = 50)
    private NotificationType notificationType;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String message;

    @Column(name = "send_push")
    @Builder.Default
    private Boolean sendPush = true;

    @Column(name = "send_sms")
    @Builder.Default
    private Boolean sendSms = false;

    @Column(name = "send_email")
    @Builder.Default
    private Boolean sendEmail = false;

    @Column(name = "is_sent")
    @Builder.Default
    private Boolean isSent = false;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "delivery_status", length = 20)
    @Builder.Default
    private String deliveryStatus = "PENDING";

    @Column(columnDefinition = "jsonb")
    private String metadata;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public void markAsSent() {
        this.isSent = true;
        this.sentAt = LocalDateTime.now();
        this.deliveryStatus = "SENT";
    }

    public boolean shouldSendPush() {
        return sendPush && !isSent;
    }

    public boolean shouldSendSms() {
        return sendSms && !isSent;
    }

    public boolean shouldSendEmail() {
        return sendEmail && !isSent;
    }

    public enum NotificationType {
        ORDER_ASSIGNED, ORDER_ACCEPTED, ORDER_PICKED_UP, OUT_FOR_DELIVERY,
        DELIVERED, DELAYED, CANCELLED, LOCATION_UPDATE
    }
}