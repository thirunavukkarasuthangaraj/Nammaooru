package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.dto.notification.NotificationResponse;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.NotificationRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {
    
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final ShopRepository shopRepository;
    private final EmailService emailService;
    
    @Transactional
    public NotificationResponse createNotification(NotificationRequest request) {
        log.info("Creating notification: {}", request.getTitle());
        
        // Handle single recipient
        if (request.getRecipientId() != null) {
            Notification notification = buildNotification(request, request.getRecipientId());
            Notification savedNotification = notificationRepository.save(notification);
            
            // Send email if requested
            if (request.getSendEmail() != null && request.getSendEmail()) {
                sendEmailNotification(savedNotification);
            }
            
            return mapToResponse(savedNotification);
        }
        
        // Handle multiple recipients
        if (request.getRecipientIds() != null && !request.getRecipientIds().isEmpty()) {
            List<Notification> notifications = new ArrayList<>();
            for (Long recipientId : request.getRecipientIds()) {
                Notification notification = buildNotification(request, recipientId);
                notifications.add(notification);
            }
            
            List<Notification> savedNotifications = notificationRepository.saveAll(notifications);
            
            // Send emails if requested
            if (request.getSendEmail() != null && request.getSendEmail()) {
                for (Notification notification : savedNotifications) {
                    sendEmailNotification(notification);
                }
            }
            
            return mapToResponse(savedNotifications.get(0)); // Return first notification
        }
        
        // Handle broadcast notifications
        if (request.getRecipientType() != null && isBroadcastType(request.getRecipientType())) {
            return createBroadcastNotification(request);
        }
        
        throw new RuntimeException("No valid recipients specified for notification");
    }
    
    @Transactional
    public NotificationResponse createBroadcastNotification(NotificationRequest request) {
        log.info("Creating broadcast notification: {} for type: {}", request.getTitle(), request.getRecipientType());
        
        List<Long> recipientIds = getBroadcastRecipients(request.getRecipientType());
        List<Notification> notifications = new ArrayList<>();
        
        for (Long recipientId : recipientIds) {
            Notification notification = buildNotification(request, recipientId);
            notifications.add(notification);
        }
        
        List<Notification> savedNotifications = notificationRepository.saveAll(notifications);
        
        // Send emails if requested
        if (request.getSendEmail() != null && request.getSendEmail()) {
            for (Notification notification : savedNotifications) {
                sendEmailNotification(notification);
            }
        }
        
        log.info("Broadcast notification created for {} recipients", savedNotifications.size());
        return mapToResponse(savedNotifications.get(0));
    }
    
    public NotificationResponse getNotificationById(Long id) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));
        return mapToResponse(notification);
    }
    
    @Transactional
    public NotificationResponse markAsRead(Long id) {
        log.info("Marking notification as read: {}", id);
        
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));
        
        notification.markAsRead();
        notification.setUpdatedBy(getCurrentUsername());
        
        Notification updatedNotification = notificationRepository.save(notification);
        log.info("Notification marked as read: {}", id);
        return mapToResponse(updatedNotification);
    }
    
    @Transactional
    public void markAllAsRead(Long recipientId) {
        log.info("Marking all notifications as read for recipient: {}", recipientId);
        notificationRepository.markAllAsRead(recipientId, LocalDateTime.now());
    }
    
    @Transactional
    public void markMultipleAsRead(List<Long> notificationIds) {
        log.info("Marking {} notifications as read", notificationIds.size());
        notificationRepository.markAsRead(notificationIds, LocalDateTime.now());
    }
    
    @Transactional
    public void deleteNotification(Long id) {
        log.info("Deleting notification: {}", id);
        
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));
        
        if (!notification.canBeDeleted()) {
            throw new RuntimeException("Cannot delete persistent notification: " + id);
        }
        
        notificationRepository.delete(notification);
        log.info("Notification deleted: {}", id);
    }
    
    @Transactional
    public void softDeleteNotifications(List<Long> notificationIds) {
        log.info("Soft deleting {} notifications", notificationIds.size());
        notificationRepository.softDeleteNotifications(notificationIds);
    }
    
    @Transactional
    public void archiveReadNotifications(Long recipientId) {
        log.info("Archiving read notifications for recipient: {}", recipientId);
        notificationRepository.archiveReadNotifications(recipientId);
    }
    
    public Page<NotificationResponse> getNotificationsForUser(Long recipientId, int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Notification> notifications = notificationRepository.findByRecipientIdAndIsActiveTrue(recipientId, pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Page<NotificationResponse> getUnreadNotifications(Long recipientId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationRepository.findByRecipientIdAndStatusAndIsActiveTrue(
                recipientId, Notification.NotificationStatus.UNREAD, pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Page<NotificationResponse> getNotificationsByType(Long recipientId, Notification.NotificationType type, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationRepository.findByRecipientIdAndTypeAndIsActiveTrue(recipientId, type, pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Page<NotificationResponse> getNotificationsByPriority(Long recipientId, Notification.NotificationPriority priority, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationRepository.findByRecipientIdAndPriorityAndIsActiveTrue(recipientId, priority, pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Page<NotificationResponse> searchNotifications(Long recipientId, String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationRepository.searchNotifications(recipientId, searchTerm, pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Long getUnreadCount(Long recipientId) {
        return notificationRepository.countUnreadNotifications(recipientId);
    }
    
    public List<NotificationResponse> getRecentNotifications(Long recipientId, int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        List<Notification> notifications = notificationRepository.findRecentNotifications(recipientId, pageable);
        return notifications.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    public List<NotificationResponse> getHighPriorityUnreadNotifications(Long recipientId) {
        List<Notification> notifications = notificationRepository.findHighPriorityUnreadNotifications(recipientId);
        return notifications.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    // Admin methods
    public Page<NotificationResponse> getAllNotifications(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Notification> notifications = notificationRepository.findAllActiveNotifications(pageable);
        return notifications.map(this::mapToResponse);
    }
    
    public Page<NotificationResponse> getBroadcastNotifications(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationRepository.findBroadcastNotifications(pageable);
        return notifications.map(this::mapToResponse);
    }
    
    // Scheduled tasks
    @Async
    @Transactional
    public void processScheduledNotifications() {
        log.info("Processing scheduled notifications");
        List<Notification> scheduledNotifications = notificationRepository.findScheduledNotifications(LocalDateTime.now());
        
        for (Notification notification : scheduledNotifications) {
            try {
                notification.markAsSent();
                notificationRepository.save(notification);
                
                // Send email if required
                if (notification.getIsEmailSent() != null && !notification.getIsEmailSent()) {
                    sendEmailNotification(notification);
                }
                
                log.debug("Processed scheduled notification: {}", notification.getId());
            } catch (Exception e) {
                log.error("Failed to process scheduled notification: {}", notification.getId(), e);
            }
        }
        
        log.info("Processed {} scheduled notifications", scheduledNotifications.size());
    }
    
    @Async
    @Transactional
    public void cleanupExpiredNotifications() {
        log.info("Cleaning up expired notifications");
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(30);
        
        // Delete old non-persistent notifications
        notificationRepository.deleteOldNotifications(cutoffDate);
        
        // Mark expired notifications as inactive
        List<Notification> expiredNotifications = notificationRepository.findExpiredNotifications(LocalDateTime.now());
        List<Long> expiredIds = expiredNotifications.stream().map(Notification::getId).collect(Collectors.toList());
        
        if (!expiredIds.isEmpty()) {
            notificationRepository.softDeleteNotifications(expiredIds);
            log.info("Marked {} expired notifications as inactive", expiredIds.size());
        }
    }
    
    // Quick notification creation methods
    public void createOrderNotification(Long customerId, Long orderId, String orderNumber, String message) {
        NotificationRequest request = NotificationRequest.builder()
                .title("Order Update")
                .message(message)
                .type(Notification.NotificationType.ORDER)
                .priority(Notification.NotificationPriority.MEDIUM)
                .recipientId(customerId)
                .recipientType(Notification.RecipientType.CUSTOMER)
                .referenceId(orderId)
                .referenceType("ORDER")
                .actionUrl("/orders/" + orderId)
                .actionText("View Order")
                .icon("shopping-cart")
                .category("ORDER")
                .sendEmail(true)
                .build();
        
        createNotification(request);
    }
    
    public void createPaymentNotification(Long customerId, String message, Notification.NotificationType type) {
        NotificationRequest request = NotificationRequest.builder()
                .title("Payment " + (type == Notification.NotificationType.SUCCESS ? "Successful" : "Failed"))
                .message(message)
                .type(type)
                .priority(Notification.NotificationPriority.HIGH)
                .recipientId(customerId)
                .recipientType(Notification.RecipientType.CUSTOMER)
                .icon(type == Notification.NotificationType.SUCCESS ? "check-circle" : "x-circle")
                .category("PAYMENT")
                .sendEmail(true)
                .build();
        
        createNotification(request);
    }
    
    public void createSystemNotification(String title, String message, Notification.NotificationPriority priority) {
        NotificationRequest request = NotificationRequest.builder()
                .title(title)
                .message(message)
                .type(Notification.NotificationType.SYSTEM)
                .priority(priority)
                .recipientType(Notification.RecipientType.ALL_USERS)
                .icon("info")
                .category("SYSTEM")
                .isPersistent(true)
                .build();
        
        createBroadcastNotification(request);
    }
    
    // Helper methods
    private Notification buildNotification(NotificationRequest request, Long recipientId) {
        return Notification.builder()
                .title(request.getTitle())
                .message(request.getMessage())
                .type(request.getType())
                .priority(request.getPriority())
                .recipientId(recipientId)
                .recipientType(request.getRecipientType())
                .senderId(request.getSenderId())
                .senderType(request.getSenderType())
                .referenceId(request.getReferenceId())
                .referenceType(request.getReferenceType())
                .actionUrl(request.getActionUrl())
                .actionText(request.getActionText())
                .icon(request.getIcon())
                .imageUrl(request.getImageUrl())
                .category(request.getCategory())
                .tags(request.getTags())
                .scheduledAt(request.getScheduledAt())
                .expiresAt(request.getExpiresAt())
                .isPersistent(request.getIsPersistent() != null ? request.getIsPersistent() : true)
                .metadata(request.getMetadata())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
    }
    
    private boolean isBroadcastType(Notification.RecipientType type) {
        return type == Notification.RecipientType.ALL_USERS ||
               type == Notification.RecipientType.ALL_CUSTOMERS ||
               type == Notification.RecipientType.ALL_SHOP_OWNERS;
    }
    
    private List<Long> getBroadcastRecipients(Notification.RecipientType type) {
        switch (type) {
            case ALL_USERS:
                return userRepository.findAll().stream().map(User::getId).collect(Collectors.toList());
            case ALL_CUSTOMERS:
                return customerRepository.findAll().stream().map(Customer::getId).collect(Collectors.toList());
            case ALL_SHOP_OWNERS:
                return shopRepository.findAll().stream().map(Shop::getId).collect(Collectors.toList());
            default:
                return new ArrayList<>();
        }
    }
    
    @Async
    private void sendEmailNotification(Notification notification) {
        try {
            String recipientEmail = getRecipientEmail(notification.getRecipientId(), notification.getRecipientType());
            String recipientName = getRecipientName(notification.getRecipientId(), notification.getRecipientType());
            
            if (recipientEmail != null) {
                emailService.sendSimpleEmail(recipientEmail, notification.getTitle(), notification.getMessage());
                
                notification.setIsEmailSent(true);
                notificationRepository.save(notification);
                
                log.info("Email notification sent to: {}", recipientEmail);
            }
        } catch (Exception e) {
            log.error("Failed to send email notification: {}", notification.getId(), e);
        }
    }
    
    private String getRecipientEmail(Long recipientId, Notification.RecipientType recipientType) {
        switch (recipientType) {
            case USER:
            case ADMIN:
                User user = userRepository.findById(recipientId).orElse(null);
                return user != null ? user.getEmail() : null;
            case CUSTOMER:
                Customer customer = customerRepository.findById(recipientId).orElse(null);
                return customer != null ? customer.getEmail() : null;
            case SHOP_OWNER:
                Shop shop = shopRepository.findById(recipientId).orElse(null);
                return shop != null ? shop.getOwnerEmail() : null;
            default:
                return null;
        }
    }
    
    private String getRecipientName(Long recipientId, Notification.RecipientType recipientType) {
        switch (recipientType) {
            case USER:
            case ADMIN:
                User user = userRepository.findById(recipientId).orElse(null);
                return user != null ? user.getFullName() : null;
            case CUSTOMER:
                Customer customer = customerRepository.findById(recipientId).orElse(null);
                return customer != null ? customer.getFullName() : null;
            case SHOP_OWNER:
                Shop shop = shopRepository.findById(recipientId).orElse(null);
                return shop != null ? shop.getOwnerName() : null;
            default:
                return null;
        }
    }
    
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
    
    private NotificationResponse mapToResponse(Notification notification) {
        String recipientName = getRecipientName(notification.getRecipientId(), notification.getRecipientType());
        String senderName = null;
        if (notification.getSenderId() != null && notification.getSenderType() != null) {
            senderName = getRecipientName(notification.getSenderId(), 
                    Notification.RecipientType.valueOf(notification.getSenderType().name()));
        }
        
        long minutesAgo = ChronoUnit.MINUTES.between(notification.getCreatedAt(), LocalDateTime.now());
        String timeAgo;
        if (minutesAgo < 1) {
            timeAgo = "Just now";
        } else if (minutesAgo < 60) {
            timeAgo = minutesAgo + " minutes ago";
        } else if (minutesAgo < 1440) {
            timeAgo = (minutesAgo / 60) + " hours ago";
        } else {
            timeAgo = (minutesAgo / 1440) + " days ago";
        }
        
        String shortMessage = notification.getMessage().length() > 100 ? 
                notification.getMessage().substring(0, 100) + "..." : notification.getMessage();
        
        return NotificationResponse.builder()
                .id(notification.getId())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .type(notification.getType())
                .priority(notification.getPriority())
                .status(notification.getStatus())
                .recipientId(notification.getRecipientId())
                .recipientType(notification.getRecipientType())
                .recipientName(recipientName)
                .senderId(notification.getSenderId())
                .senderType(notification.getSenderType())
                .senderName(senderName)
                .referenceId(notification.getReferenceId())
                .referenceType(notification.getReferenceType())
                .actionUrl(notification.getActionUrl())
                .actionText(notification.getActionText())
                .icon(notification.getIcon())
                .imageUrl(notification.getImageUrl())
                .category(notification.getCategory())
                .tags(notification.getTags())
                .scheduledAt(notification.getScheduledAt())
                .sentAt(notification.getSentAt())
                .readAt(notification.getReadAt())
                .expiresAt(notification.getExpiresAt())
                .isActive(notification.getIsActive())
                .isPersistent(notification.getIsPersistent())
                .isEmailSent(notification.getIsEmailSent())
                .isPushSent(notification.getIsPushSent())
                .metadata(notification.getMetadata())
                .createdAt(notification.getCreatedAt())
                .updatedAt(notification.getUpdatedAt())
                .createdBy(notification.getCreatedBy())
                .updatedBy(notification.getUpdatedBy())
                .typeLabel(notification.getType().name())
                .priorityLabel(notification.getPriority().name())
                .statusLabel(notification.getStatus().name())
                .recipientTypeLabel(notification.getRecipientType().name())
                .senderTypeLabel(notification.getSenderType() != null ? notification.getSenderType().name() : null)
                .isRead(notification.isRead())
                .isExpired(notification.isExpired())
                .canBeDeleted(notification.canBeDeleted())
                .timeAgo(timeAgo)
                .formattedCreatedAt(notification.getCreatedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")))
                .shortMessage(shortMessage)
                .build();
    }
}