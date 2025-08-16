package com.shopmanagement.controller;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.dto.notification.NotificationResponse;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.service.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
public class NotificationController {
    
    private final NotificationService notificationService;
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<NotificationResponse> createNotification(@Valid @RequestBody NotificationRequest request) {
        log.info("Creating notification: {}", request.getTitle());
        NotificationResponse response = notificationService.createNotification(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @PostMapping("/broadcast")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<NotificationResponse> createBroadcastNotification(@Valid @RequestBody NotificationRequest request) {
        log.info("Creating broadcast notification: {}", request.getTitle());
        NotificationResponse response = notificationService.createBroadcastNotification(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<NotificationResponse> getNotificationById(@PathVariable Long id) {
        log.info("Fetching notification with ID: {}", id);
        NotificationResponse response = notificationService.getNotificationById(id);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{id}/read")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<NotificationResponse> markAsRead(@PathVariable Long id) {
        log.info("Marking notification as read: {}", id);
        NotificationResponse response = notificationService.markAsRead(id);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/user/{userId}/read-all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Void> markAllAsRead(@PathVariable Long userId) {
        log.info("Marking all notifications as read for user: {}", userId);
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/read-multiple")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Void> markMultipleAsRead(@RequestBody List<Long> notificationIds) {
        log.info("Marking {} notifications as read", notificationIds.size());
        notificationService.markMultipleAsRead(notificationIds);
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Void> deleteNotification(@PathVariable Long id) {
        log.info("Deleting notification: {}", id);
        notificationService.deleteNotification(id);
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping("/soft-delete")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Void> softDeleteNotifications(@RequestBody List<Long> notificationIds) {
        log.info("Soft deleting {} notifications", notificationIds.size());
        notificationService.softDeleteNotifications(notificationIds);
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/user/{userId}/archive-read")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Void> archiveReadNotifications(@PathVariable Long userId) {
        log.info("Archiving read notifications for user: {}", userId);
        notificationService.archiveReadNotifications(userId);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Page<NotificationResponse>> getNotificationsForUser(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching notifications for user: {} - page: {}, size: {}", userId, page, size);
        Page<NotificationResponse> response = notificationService.getNotificationsForUser(userId, page, size, sortBy, sortDirection);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/unread")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Page<NotificationResponse>> getUnreadNotifications(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching unread notifications for user: {}", userId);
        Page<NotificationResponse> response = notificationService.getUnreadNotifications(userId, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/type/{type}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Page<NotificationResponse>> getNotificationsByType(
            @PathVariable Long userId,
            @PathVariable String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching notifications by type: {} for user: {}", type, userId);
        Notification.NotificationType notificationType = Notification.NotificationType.valueOf(type.toUpperCase());
        Page<NotificationResponse> response = notificationService.getNotificationsByType(userId, notificationType, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/priority/{priority}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Page<NotificationResponse>> getNotificationsByPriority(
            @PathVariable Long userId,
            @PathVariable String priority,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching notifications by priority: {} for user: {}", priority, userId);
        Notification.NotificationPriority notificationPriority = Notification.NotificationPriority.valueOf(priority.toUpperCase());
        Page<NotificationResponse> response = notificationService.getNotificationsByPriority(userId, notificationPriority, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Page<NotificationResponse>> searchNotifications(
            @PathVariable Long userId,
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching notifications for user: {} with term: {}", userId, searchTerm);
        Page<NotificationResponse> response = notificationService.searchNotifications(userId, searchTerm, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/count/unread")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<Long> getUnreadCount(@PathVariable Long userId) {
        log.info("Fetching unread count for user: {}", userId);
        Long count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(count);
    }
    
    @GetMapping("/user/{userId}/recent")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<List<NotificationResponse>> getRecentNotifications(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "5") int limit) {
        log.info("Fetching recent notifications for user: {} (limit: {})", userId, limit);
        List<NotificationResponse> response = notificationService.getRecentNotifications(userId, limit);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}/high-priority-unread")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<List<NotificationResponse>> getHighPriorityUnreadNotifications(@PathVariable Long userId) {
        log.info("Fetching high priority unread notifications for user: {}", userId);
        List<NotificationResponse> response = notificationService.getHighPriorityUnreadNotifications(userId);
        return ResponseEntity.ok(response);
    }
    
    // Admin endpoints
    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Page<NotificationResponse>> getAllNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching all notifications - page: {}, size: {}", page, size);
        Page<NotificationResponse> response = notificationService.getAllNotifications(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/admin/broadcast")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Page<NotificationResponse>> getBroadcastNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching broadcast notifications - page: {}, size: {}", page, size);
        Page<NotificationResponse> response = notificationService.getBroadcastNotifications(page, size);
        return ResponseEntity.ok(response);
    }
    
    // System maintenance endpoints
    @PostMapping("/system/process-scheduled")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> processScheduledNotifications() {
        log.info("Processing scheduled notifications");
        notificationService.processScheduledNotifications();
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/system/cleanup-expired")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> cleanupExpiredNotifications() {
        log.info("Cleaning up expired notifications");
        notificationService.cleanupExpiredNotifications();
        return ResponseEntity.ok().build();
    }
    
    // Quick notification creation endpoints
    @PostMapping("/quick/order")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Void> createOrderNotification(
            @RequestParam Long customerId,
            @RequestParam Long orderId,
            @RequestParam String orderNumber,
            @RequestParam String message) {
        log.info("Creating order notification for customer: {} and order: {}", customerId, orderId);
        notificationService.createOrderNotification(customerId, orderId, orderNumber, message);
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/quick/payment")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Void> createPaymentNotification(
            @RequestParam Long customerId,
            @RequestParam String message,
            @RequestParam String type) {
        log.info("Creating payment notification for customer: {} with type: {}", customerId, type);
        Notification.NotificationType notificationType = Notification.NotificationType.valueOf(type.toUpperCase());
        notificationService.createPaymentNotification(customerId, message, notificationType);
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/quick/system")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> createSystemNotification(
            @RequestParam String title,
            @RequestParam String message,
            @RequestParam String priority) {
        log.info("Creating system notification: {}", title);
        Notification.NotificationPriority notificationPriority = Notification.NotificationPriority.valueOf(priority.toUpperCase());
        notificationService.createSystemNotification(title, message, notificationPriority);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getNotificationEnums() {
        return ResponseEntity.ok(Map.of(
                "notificationTypes", Notification.NotificationType.values(),
                "notificationPriorities", Notification.NotificationPriority.values(),
                "notificationStatuses", Notification.NotificationStatus.values(),
                "recipientTypes", Notification.RecipientType.values(),
                "senderTypes", Notification.SenderType.values()
        ));
    }
}