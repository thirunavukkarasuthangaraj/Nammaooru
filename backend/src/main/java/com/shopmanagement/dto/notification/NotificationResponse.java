package com.shopmanagement.dto.notification;

import com.shopmanagement.entity.Notification;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationResponse {
    
    private Long id;
    private String title;
    private String message;
    private Notification.NotificationType type;
    private Notification.NotificationPriority priority;
    private Notification.NotificationStatus status;
    private Long recipientId;
    private Notification.RecipientType recipientType;
    private String recipientName;
    private Long senderId;
    private Notification.SenderType senderType;
    private String senderName;
    private Long referenceId;
    private String referenceType;
    private String actionUrl;
    private String actionText;
    private String icon;
    private String imageUrl;
    private String category;
    private String tags;
    private LocalDateTime scheduledAt;
    private LocalDateTime sentAt;
    private LocalDateTime readAt;
    private LocalDateTime expiresAt;
    private Boolean isActive;
    private Boolean isPersistent;
    private Boolean isEmailSent;
    private Boolean isPushSent;
    private String metadata;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Helper fields
    private String typeLabel;
    private String priorityLabel;
    private String statusLabel;
    private String recipientTypeLabel;
    private String senderTypeLabel;
    private boolean isRead;
    private boolean isExpired;
    private boolean canBeDeleted;
    private String timeAgo;
    private String formattedCreatedAt;
    private String shortMessage;
}