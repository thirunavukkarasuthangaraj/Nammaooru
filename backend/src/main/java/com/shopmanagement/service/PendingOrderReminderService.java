package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Service to send periodic push notifications to shop owners for pending orders
 * that haven't been accepted yet.
 *
 * Reminder Logic:
 * - Check every 1 minute for pending orders
 * - Send push notification reminder to shop owner
 * - Track notification count to avoid spam
 * - Stop reminders after order is accepted/rejected/cancelled
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PendingOrderReminderService {

    private final OrderRepository orderRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final UserRepository userRepository;
    private final FirebaseNotificationService firebaseNotificationService;

    // Track notification counts for each order
    private final ConcurrentHashMap<Long, Integer> reminderCounts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, LocalDateTime> firstReminderTime = new ConcurrentHashMap<>();

    /**
     * Scheduled task that runs every 1 minute to send reminders for pending orders
     */
    @Scheduled(fixedDelay = 60000, initialDelay = 45000) // Run every 1 minute, start after 45 seconds
    @Transactional
    public void sendPendingOrderReminders() {
        try {
            log.debug("Checking for pending orders that need reminders...");

            // Find all orders with PENDING status
            List<Order> pendingOrders = orderRepository.findByStatus(Order.OrderStatus.PENDING);

            if (pendingOrders.isEmpty()) {
                log.debug("No pending orders found");
                return;
            }

            log.info("Found {} pending orders to process for reminders", pendingOrders.size());

            for (Order order : pendingOrders) {
                processPendingOrder(order);
            }

            // Cleanup old tracking data for orders that are no longer pending
            cleanupCompletedOrders();

        } catch (Exception e) {
            log.error("Error in sendPendingOrderReminders scheduled task: {}", e.getMessage(), e);
        }
    }

    /**
     * Process a single pending order and send reminder if needed
     */
    private void processPendingOrder(Order order) {
        Long orderId = order.getId();

        try {
            // Track first reminder time
            firstReminderTime.putIfAbsent(orderId, LocalDateTime.now());
            LocalDateTime firstReminder = firstReminderTime.get(orderId);

            // Get current reminder count
            int currentCount = reminderCounts.getOrDefault(orderId, 0);

            // Calculate how long order has been pending
            long minutesPending = java.time.Duration.between(order.getCreatedAt(), LocalDateTime.now()).toMinutes();

            log.info("🔔 Processing pending order reminder: {} (Count: {}, Pending: {} minutes)",
                order.getOrderNumber(), currentCount + 1, minutesPending);

            // Get shop owner user
            String shopOwnerEmail = order.getShop().getOwnerEmail();
            User shopOwner = userRepository.findByEmail(shopOwnerEmail).orElse(null);

            if (shopOwner == null) {
                log.warn("⚠️ Shop owner user not found for email: {}", shopOwnerEmail);
                return;
            }

            // Get active FCM tokens for shop owner
            List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());

            if (fcmTokens.isEmpty()) {
                log.warn("⚠️ No active FCM tokens found for shop owner {}. Cannot send reminder.", shopOwnerEmail);
                // Increment count even if no tokens (to avoid excessive logging)
                reminderCounts.put(orderId, currentCount + 1);
                return;
            }

            // Send reminder notification to all active devices
            for (UserFcmToken fcmToken : fcmTokens) {
                try {
                    sendReminderNotification(order, fcmToken, currentCount + 1);
                    log.info("✅ Reminder notification sent successfully to shop owner's device ({})",
                        fcmToken.getDeviceType());
                } catch (Exception e) {
                    log.error("❌ Failed to send reminder to device {}: {}",
                        fcmToken.getDeviceType(), e.getMessage());
                }
            }

            // Increment reminder count
            reminderCounts.put(orderId, currentCount + 1);

        } catch (Exception e) {
            log.error("Error processing pending order reminder for order {}: {}",
                order.getOrderNumber(), e.getMessage(), e);
        }
    }

    /**
     * Send reminder notification for a pending order
     */
    private void sendReminderNotification(Order order, UserFcmToken fcmToken, int reminderCount) {
        String title = "⏰ Pending Order Reminder #" + reminderCount;
        String body = String.format("Order %s from %s is still waiting for acceptance! %d items - ₹%.2f",
            order.getOrderNumber(),
            order.getCustomer().getFullName(),
            order.getOrderItems().size(),
            order.getTotalAmount().doubleValue());

        log.info("📄 Sending reminder #{} for order: {}", reminderCount, order.getOrderNumber());
        log.info("📱 Title: '{}', Body: '{}'", title, body);

        firebaseNotificationService.sendNewOrderNotificationToShopOwner(
            order.getOrderNumber(),
            fcmToken.getFcmToken(),
            fcmToken.getUserId(),
            order.getCustomer().getFullName(),
            order.getTotalAmount().doubleValue(),
            order.getOrderItems().size()
        );
    }

    /**
     * Clean up tracking data for orders that are no longer pending
     */
    private void cleanupCompletedOrders() {
        try {
            // Get list of all order IDs we're tracking
            List<Long> trackedOrderIds = reminderCounts.keySet().stream().toList();

            for (Long orderId : trackedOrderIds) {
                // Check if order still exists and is still pending
                Order order = orderRepository.findById(orderId).orElse(null);

                if (order == null || order.getStatus() != Order.OrderStatus.PENDING) {
                    // Order is no longer pending - clean up tracking
                    int finalCount = reminderCounts.remove(orderId);
                    LocalDateTime firstReminder = firstReminderTime.remove(orderId);

                    if (order != null) {
                        log.info("✅ Order {} status changed to {}. Sent {} reminders. Stopping further reminders.",
                            order.getOrderNumber(), order.getStatus(), finalCount);
                    } else {
                        log.info("🗑️ Order ID {} no longer exists. Cleaning up tracking data.", orderId);
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error in cleanupCompletedOrders: {}", e.getMessage(), e);
        }
    }

    /**
     * Manually clear tracking for an order (useful after acceptance/rejection)
     */
    public void clearOrderTracking(Long orderId) {
        Integer count = reminderCounts.remove(orderId);
        firstReminderTime.remove(orderId);

        if (count != null) {
            log.info("Cleared reminder tracking for order ID: {} ({} reminders sent)", orderId, count);
        }
    }

    /**
     * Get reminder status for an order
     */
    public ReminderStatus getReminderStatus(Long orderId) {
        Integer count = reminderCounts.get(orderId);
        LocalDateTime firstReminder = firstReminderTime.get(orderId);

        if (count == null || firstReminder == null) {
            return new ReminderStatus(0, null, 0);
        }

        long minutesSinceFirst = java.time.Duration.between(firstReminder, LocalDateTime.now()).toMinutes();

        return new ReminderStatus(count, firstReminder, minutesSinceFirst);
    }

    /**
     * Data class for reminder status
     */
    public static class ReminderStatus {
        public final int reminderCount;
        public final LocalDateTime firstReminderTime;
        public final long minutesSinceFirst;

        public ReminderStatus(int reminderCount, LocalDateTime firstReminderTime, long minutesSinceFirst) {
            this.reminderCount = reminderCount;
            this.firstReminderTime = firstReminderTime;
            this.minutesSinceFirst = minutesSinceFirst;
        }
    }
}
