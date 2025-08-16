package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Notification {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 200)
    private String title;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationType type;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationPriority priority;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private NotificationStatus status = NotificationStatus.UNREAD;
    
    @Column(name = "recipient_id", nullable = false)
    private Long recipientId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_type", nullable = false, length = 20)
    private RecipientType recipientType;
    
    @Column(name = "sender_id")
    private Long senderId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "sender_type", length = 20)
    private SenderType senderType;
    
    @Column(name = "reference_id")
    private Long referenceId;
    
    @Column(name = "reference_type", length = 50)
    private String referenceType;
    
    @Column(name = "action_url", length = 500)
    private String actionUrl;
    
    @Column(name = "action_text", length = 100)
    private String actionText;
    
    @Column(name = "icon", length = 100)
    private String icon;
    
    @Column(name = "image_url", length = 500)
    private String imageUrl;
    
    @Column(name = "category", length = 100)
    private String category;
    
    @Column(name = "tags", length = 500)
    private String tags;
    
    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;
    
    @Column(name = "sent_at")
    private LocalDateTime sentAt;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
    
    @Column(name = "expires_at")
    private LocalDateTime expiresAt;
    
    @Builder.Default
    private Boolean isActive = true;
    
    @Builder.Default
    private Boolean isPersistent = true;
    
    @Builder.Default
    private Boolean isEmailSent = false;
    
    @Builder.Default
    private Boolean isPushSent = false;
    
    @Column(name = "metadata", columnDefinition = "TEXT")
    private String metadata;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "created_by", length = 100)
    private String createdBy;
    
    @Column(name = "updated_by", length = 100)
    private String updatedBy;
    
    // Helper methods
    public boolean isRead() {
        return status == NotificationStatus.READ;
    }
    
    public boolean isExpired() {
        return expiresAt != null && expiresAt.isBefore(LocalDateTime.now());
    }
    
    public boolean canBeDeleted() {
        return !isPersistent || isExpired();
    }
    
    public void markAsRead() {
        this.status = NotificationStatus.READ;
        this.readAt = LocalDateTime.now();
    }
    
    public void markAsSent() {
        this.sentAt = LocalDateTime.now();
    }
    
    public enum NotificationType {
        INFO, SUCCESS, WARNING, ERROR, ORDER, PAYMENT, SYSTEM, PROMOTION, REMINDER, ANNOUNCEMENT
    }
    
    public enum NotificationPriority {
        LOW, MEDIUM, HIGH, URGENT
    }
    
    public enum NotificationStatus {
        UNREAD, READ, ARCHIVED, DELETED
    }
    
    public enum RecipientType {
        USER, CUSTOMER, SHOP_OWNER, ADMIN, ALL_USERS, ALL_CUSTOMERS, ALL_SHOP_OWNERS
    }
    
    public enum SenderType {
        SYSTEM, USER, ADMIN, SHOP_OWNER, CUSTOMER
    }
}