package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Service to retry auto-assignment of delivery partners for orders
 * that couldn't be assigned initially due to no available partners.
 *
 * Retry Logic:
 * - Check every 1 minute for unassigned orders
 * - Retry for 3 minutes (3 attempts)
 * - After 3 minutes, send alert email to admin
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OrderAssignmentRetryService {

    private final OrderRepository orderRepository;
    private final OrderAssignmentRepository orderAssignmentRepository;
    private final OrderAssignmentService orderAssignmentService;
    private final EmailService emailService;

    @Value("${app.admin.email:thirunacse75@gmail.com}")
    private String adminEmail;

    @Value("${app.assignment.retry.max-attempts:3}")
    private int maxRetryAttempts;

    @Value("${app.assignment.retry.max-age-minutes:10}")
    private int maxOrderAgeMinutes;

    // Track retry attempts for each order
    private final ConcurrentHashMap<Long, Integer> retryAttempts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, LocalDateTime> firstAttemptTime = new ConcurrentHashMap<>();

    /**
     * Scheduled task that runs every 1 minute to check for unassigned orders
     * and retry auto-assignment
     */
    @Scheduled(fixedDelay = 60000, initialDelay = 30000) // Run every 1 minute, start after 30 seconds
    @Transactional
    public void retryUnassignedOrders() {
        try {
            log.debug("Checking for unassigned orders...");

            // Find orders that are READY_FOR_PICKUP with HOME_DELIVERY type
            List<Order> readyOrders = orderRepository.findByStatusAndDeliveryType(
                Order.OrderStatus.READY_FOR_PICKUP,
                Order.DeliveryType.HOME_DELIVERY
            );

            if (readyOrders.isEmpty()) {
                log.debug("No ready orders found");
                return;
            }

            // Filter to only unassigned orders (no accepted OrderAssignment)
            List<Order> unassignedOrders = readyOrders.stream()
                .filter(order -> {
                    List<OrderAssignment> assignments = orderAssignmentRepository.findByOrderId(order.getId());
                    return assignments.stream().noneMatch(a ->
                        a.getStatus() == OrderAssignment.AssignmentStatus.ACCEPTED ||
                        a.getStatus() == OrderAssignment.AssignmentStatus.PICKED_UP ||
                        a.getStatus() == OrderAssignment.AssignmentStatus.DELIVERED
                    );
                })
                .toList();

            if (unassignedOrders.isEmpty()) {
                log.debug("No unassigned orders found (all have delivery partners)");
                return;
            }

            log.info("Found {} unassigned orders ready for delivery", unassignedOrders.size());

            for (Order order : unassignedOrders) {
                processUnassignedOrder(order);
            }

            // Cleanup old tracking data (orders older than maxOrderAgeMinutes)
            cleanupOldTracking();

        } catch (Exception e) {
            log.error("Error in retryUnassignedOrders scheduled task: {}", e.getMessage(), e);
        }
    }

    /**
     * Process a single unassigned order
     */
    private void processUnassignedOrder(Order order) {
        Long orderId = order.getId();

        // Track first attempt time
        firstAttemptTime.putIfAbsent(orderId, LocalDateTime.now());
        LocalDateTime firstAttempt = firstAttemptTime.get(orderId);

        // Calculate how long we've been trying
        long minutesSinceFirst = java.time.Duration.between(firstAttempt, LocalDateTime.now()).toMinutes();

        // Get current retry count
        int currentAttempts = retryAttempts.getOrDefault(orderId, 0);

        log.info("Processing unassigned order: {} (Attempt: {}, Age: {} minutes)",
            order.getOrderNumber(), currentAttempts + 1, minutesSinceFirst);

        // If we've been trying for more than maxOrderAgeMinutes, stop and send final alert
        if (minutesSinceFirst >= maxOrderAgeMinutes) {
            log.warn("Order {} has been unassigned for {} minutes. Stopping retry and sending final alert.",
                order.getOrderNumber(), minutesSinceFirst);
            sendFinalAlert(order, currentAttempts);
            retryAttempts.remove(orderId);
            firstAttemptTime.remove(orderId);
            return;
        }

        // Try to auto-assign
        try {
            OrderAssignment assignment = orderAssignmentService.autoAssignOrder(
                orderId,
                null  // null means system auto-assignment (no specific user)
            );

            // Success!
            log.info("✅ Successfully assigned order {} to partner {} on attempt {}",
                order.getOrderNumber(),
                assignment.getDeliveryPartner().getEmail(),
                currentAttempts + 1);

            // Send success notification if it took multiple attempts
            if (currentAttempts > 0) {
                emailService.sendOrderAssignedAfterRetryNotification(
                    order.getOrderNumber(),
                    assignment.getDeliveryPartner().getFullName(),
                    adminEmail,
                    currentAttempts + 1
                );
            }

            // Clean up tracking
            retryAttempts.remove(orderId);
            firstAttemptTime.remove(orderId);

        } catch (Exception e) {
            // Assignment failed - increment retry count
            int newAttemptCount = currentAttempts + 1;
            retryAttempts.put(orderId, newAttemptCount);

            log.warn("Failed to assign order {} (Attempt {}/{}): {}",
                order.getOrderNumber(), newAttemptCount, maxRetryAttempts, e.getMessage());

            // If we've reached 3 minutes (3 attempts), send alert email
            if (newAttemptCount >= maxRetryAttempts) {
                log.error("⚠️  Order {} failed auto-assignment after {} attempts. Sending alert to admin and shop owner.",
                    order.getOrderNumber(), newAttemptCount);

                // Send alert to platform admin
                emailService.sendNoPartnersAvailableAlert(
                    order.getId(),
                    order.getOrderNumber(),
                    order.getShop().getName(),
                    adminEmail,
                    newAttemptCount
                );

                // Send alert to shop owner
                String shopOwnerEmail = order.getShop().getOwnerEmail();
                if (shopOwnerEmail != null && !shopOwnerEmail.isEmpty()) {
                    emailService.sendNoPartnersAvailableAlert(
                        order.getId(),
                        order.getOrderNumber(),
                        order.getShop().getName(),
                        shopOwnerEmail,
                        newAttemptCount
                    );
                    log.info("Alert email sent to shop owner: {}", shopOwnerEmail);
                }
            }
        }
    }

    /**
     * Send final alert when order has been unassigned for too long
     */
    private void sendFinalAlert(Order order, int attempts) {
        try {
            String subject = "🚨 CRITICAL: Order Still Unassigned After " + maxOrderAgeMinutes + " Minutes - " + order.getOrderNumber();

            String body = String.format(
                "🚨 CRITICAL ALERT: Order Requires Immediate Manual Assignment\n\n" +
                "Order %s has been waiting for delivery partner assignment for %d minutes.\n\n" +
                "Order Details:\n" +
                "- Order ID: %d\n" +
                "- Order Number: %s\n" +
                "- Shop: %s\n" +
                "- Customer: %s\n" +
                "- Total Attempts: %d\n" +
                "- First Attempt: %s\n" +
                "- Current Time: %s\n\n" +
                "⚡ IMMEDIATE ACTION REQUIRED:\n" +
                "1. Log into admin dashboard immediately\n" +
                "2. Manually assign a delivery partner\n" +
                "3. Contact delivery partners to come online\n" +
                "4. Consider hiring more delivery partners\n\n" +
                "Customer is waiting and may contact support!\n\n" +
                "This is a CRITICAL automated alert from NammaOoru Shop Management System.",
                order.getOrderNumber(), maxOrderAgeMinutes,
                order.getId(),
                order.getOrderNumber(),
                order.getShop().getName(),
                order.getCustomer().getFullName(),
                attempts,
                firstAttemptTime.get(order.getId()),
                LocalDateTime.now()
            );

            // Send to platform admin
            emailService.sendSimpleEmail(adminEmail, subject, body);
            log.error("🚨 Critical alert sent to admin for order: {}", order.getOrderNumber());

            // Send to shop owner
            String shopOwnerEmail = order.getShop().getOwnerEmail();
            if (shopOwnerEmail != null && !shopOwnerEmail.isEmpty()) {
                emailService.sendSimpleEmail(shopOwnerEmail, subject, body);
                log.error("🚨 Critical alert sent to shop owner ({}) for order: {}", shopOwnerEmail, order.getOrderNumber());
            }

        } catch (Exception e) {
            log.error("Failed to send final alert for order {}: {}", order.getOrderNumber(), e.getMessage(), e);
        }
    }

    /**
     * Clean up tracking data for old orders
     */
    private void cleanupOldTracking() {
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(maxOrderAgeMinutes + 5);

        firstAttemptTime.entrySet().removeIf(entry -> {
            if (entry.getValue().isBefore(cutoffTime)) {
                log.debug("Cleaning up old tracking data for order ID: {}", entry.getKey());
                retryAttempts.remove(entry.getKey());
                return true;
            }
            return false;
        });
    }

    /**
     * Manually clear tracking for an order (useful after manual assignment)
     */
    public void clearOrderTracking(Long orderId) {
        retryAttempts.remove(orderId);
        firstAttemptTime.remove(orderId);
        log.info("Cleared retry tracking for order ID: {}", orderId);
    }

    /**
     * Get retry status for an order
     */
    public RetryStatus getRetryStatus(Long orderId) {
        Integer attempts = retryAttempts.get(orderId);
        LocalDateTime firstAttempt = firstAttemptTime.get(orderId);

        if (attempts == null || firstAttempt == null) {
            return new RetryStatus(0, null, 0);
        }

        long minutesSinceFirst = java.time.Duration.between(firstAttempt, LocalDateTime.now()).toMinutes();

        return new RetryStatus(attempts, firstAttempt, minutesSinceFirst);
    }

    /**
     * Data class for retry status
     */
    public static class RetryStatus {
        public final int attempts;
        public final LocalDateTime firstAttemptTime;
        public final long minutesSinceFirst;

        public RetryStatus(int attempts, LocalDateTime firstAttemptTime, long minutesSinceFirst) {
            this.attempts = attempts;
            this.firstAttemptTime = firstAttemptTime;
            this.minutesSinceFirst = minutesSinceFirst;
        }
    }
}
