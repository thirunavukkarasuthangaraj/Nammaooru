package com.shopmanagement.dto.notification;

import com.shopmanagement.entity.Notification;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationRequest {
    
    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title cannot exceed 200 characters")
    private String title;
    
    @NotBlank(message = "Message is required")
    private String message;
    
    @NotNull(message = "Notification type is required")
    private Notification.NotificationType type;
    
    @NotNull(message = "Priority is required")
    private Notification.NotificationPriority priority;
    
    private Long recipientId;
    
    @NotNull(message = "Recipient type is required")
    private Notification.RecipientType recipientType;
    
    private List<Long> recipientIds;
    
    private Long senderId;
    
    private Notification.SenderType senderType;
    
    private Long referenceId;
    
    @Size(max = 50, message = "Reference type cannot exceed 50 characters")
    private String referenceType;
    
    @Size(max = 500, message = "Action URL cannot exceed 500 characters")
    private String actionUrl;
    
    @Size(max = 100, message = "Action text cannot exceed 100 characters")
    private String actionText;
    
    @Size(max = 100, message = "Icon cannot exceed 100 characters")
    private String icon;
    
    @Size(max = 500, message = "Image URL cannot exceed 500 characters")
    private String imageUrl;
    
    @Size(max = 100, message = "Category cannot exceed 100 characters")
    private String category;
    
    @Size(max = 500, message = "Tags cannot exceed 500 characters")
    private String tags;
    
    private LocalDateTime scheduledAt;
    
    private LocalDateTime expiresAt;
    
    private Boolean isPersistent;
    
    private Boolean sendEmail;
    
    private Boolean sendPush;

    private String metadata;

    // Location-based targeting
    private Double latitude;
    private Double longitude;
    private Double radiusKm;
}