package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DriverSearchSchedulerService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final OrderAssignmentService orderAssignmentService;
    private final FirebaseNotificationService firebaseNotificationService;

    // Search timeout in minutes
    private static final int SEARCH_TIMEOUT_MINUTES = 3;
    // Maximum retry attempts
    private static final int MAX_RETRY_ATTEMPTS = 6; // 6 attempts x 30 seconds = 3 minutes

    /**
     * Scheduled task that runs every 30 seconds to retry driver search
     * for orders that are searching for drivers
     */
    @Scheduled(fixedRate = 30000) // Run every 30 seconds
    @Transactional
    public void retryDriverSearch() {
        try {
            // Find orders that are searching for drivers (READY_FOR_PICKUP with search started but not completed)
            List<Order> searchingOrders = orderRepository.findByStatusAndDriverSearchStartedAtIsNotNullAndDriverSearchCompletedFalse(
                Order.OrderStatus.READY_FOR_PICKUP
            );

            if (searchingOrders.isEmpty()) {
                return; // No orders searching for drivers
            }

            log.info("🔍 Found {} orders searching for drivers", searchingOrders.size());

            for (Order order : searchingOrders) {
                processDriverSearch(order);
            }
        } catch (Exception e) {
            log.error("❌ Error in driver search scheduler: {}", e.getMessage(), e);
        }
    }

    private void processDriverSearch(Order order) {
        try {
            LocalDateTime searchStarted = order.getDriverSearchStartedAt();
            long minutesElapsed = ChronoUnit.MINUTES.between(searchStarted, LocalDateTime.now());
            int attempts = order.getDriverSearchAttempts() != null ? order.getDriverSearchAttempts() : 0;

            log.info("📊 Order {} - Search elapsed: {} minutes, Attempts: {}",
                order.getOrderNumber(), minutesElapsed, attempts);

            // Check if timeout exceeded
            if (minutesElapsed >= SEARCH_TIMEOUT_MINUTES || attempts >= MAX_RETRY_ATTEMPTS) {
                handleSearchTimeout(order);
                return;
            }

            // Try to find available driver
            List<User> availablePartners = userRepository.findByRoleAndIsActiveAndIsAvailableAndIsOnline(
                User.UserRole.DELIVERY_PARTNER, true, true, true
            );

            if (!availablePartners.isEmpty()) {
                // Driver found! Try to assign
                log.info("✅ Found {} available drivers for order {}", availablePartners.size(), order.getOrderNumber());

                try {
                    // Get shop owner ID for assignment
                    String shopOwnerEmail = order.getShop().getOwnerEmail();
                    User shopOwnerUser = userRepository.findByEmail(shopOwnerEmail).orElse(null);
                    Long shopOwnerId = shopOwnerUser != null ? shopOwnerUser.getId() : 1L;
                    OrderAssignment assignment = orderAssignmentService.autoAssignOrder(order.getId(), shopOwnerId);

                    // Mark search as completed
                    order.setDriverSearchCompleted(true);
                    orderRepository.save(order);

                    log.info("✅ Order {} successfully assigned to driver after {} attempts",
                        order.getOrderNumber(), attempts);
                } catch (Exception e) {
                    log.warn("⚠️ Failed to assign order {}: {}", order.getOrderNumber(), e.getMessage());
                    // Increment attempts and continue searching
                    order.setDriverSearchAttempts(attempts + 1);
                    orderRepository.save(order);
                }
            } else {
                // No driver found, increment attempts
                order.setDriverSearchAttempts(attempts + 1);
                orderRepository.save(order);
                log.info("🔄 No drivers available for order {}. Attempt {}/{}",
                    order.getOrderNumber(), attempts + 1, MAX_RETRY_ATTEMPTS);
            }
        } catch (Exception e) {
            log.error("❌ Error processing driver search for order {}: {}",
                order.getOrderNumber(), e.getMessage(), e);
        }
    }

    private void handleSearchTimeout(Order order) {
        log.info("⏰ Driver search timeout for order {}. Notifying shop owner and customer.",
            order.getOrderNumber());

        // Mark search as completed (failed)
        order.setDriverSearchCompleted(true);
        // Keep order at READY status (not READY_FOR_PICKUP) so shop owner can try again
        order.setStatus(Order.OrderStatus.READY);
        orderRepository.save(order);

        // Send FCM to shop owner
        sendNoDriverNotificationToShopOwner(order);

        // Send FCM to customer
        sendNoDriverNotificationToCustomer(order);

        log.info("✅ Order {} moved back to READY status. Shop owner can try again.",
            order.getOrderNumber());
    }

    private void sendNoDriverNotificationToShopOwner(Order order) {
        try {
            String shopOwnerEmail = order.getShop().getOwnerEmail();
            User shopOwner = userRepository.findByEmail(shopOwnerEmail).orElse(null);
            if (shopOwner != null) {
                List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());

                for (UserFcmToken tokenEntity : tokens) {
                    try {
                        firebaseNotificationService.sendOrderNotification(
                            order.getOrderNumber(),
                            "NO_DRIVER_AVAILABLE",
                            tokenEntity.getFcmToken(),
                            shopOwner.getId()
                        );
                        log.info("✅ No driver FCM sent to shop owner for order: {}", order.getOrderNumber());
                        break;
                    } catch (Exception e) {
                        log.warn("⚠️ Failed to send no driver FCM to shop owner: {}", e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.error("❌ Error sending no driver notification to shop owner: {}", e.getMessage());
        }
    }

    private void sendNoDriverNotificationToCustomer(Order order) {
        try {
            if (order.getCustomer() != null && order.getCustomer().getEmail() != null) {
                User customerUser = userRepository.findByEmail(order.getCustomer().getEmail()).orElse(null);

                if (customerUser != null) {
                    List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(customerUser.getId());

                    for (UserFcmToken tokenEntity : tokens) {
                        try {
                            firebaseNotificationService.sendOrderNotification(
                                order.getOrderNumber(),
                                "NO_DRIVER_AVAILABLE",
                                tokenEntity.getFcmToken(),
                                order.getCustomer().getId()
                            );
                            log.info("✅ No driver FCM sent to customer for order: {}", order.getOrderNumber());
                            break;
                        } catch (Exception e) {
                            log.warn("⚠️ Failed to send no driver FCM to customer: {}", e.getMessage());
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("❌ Error sending no driver notification to customer: {}", e.getMessage());
        }
    }

    /**
     * Start driver search for an order
     * Called when shop owner marks order as READY_FOR_PICKUP
     */
    @Transactional
    public void startDriverSearch(Order order) {
        log.info("🔍 Starting driver search for order: {}", order.getOrderNumber());

        order.setDriverSearchStartedAt(LocalDateTime.now());
        order.setDriverSearchAttempts(0);
        order.setDriverSearchCompleted(false);
        orderRepository.save(order);

        log.info("✅ Driver search started for order: {}. Will timeout in {} minutes.",
            order.getOrderNumber(), SEARCH_TIMEOUT_MINUTES);
    }

    /**
     * Reset driver search for retry
     * Called when shop owner clicks "Try Again"
     */
    @Transactional
    public void resetDriverSearch(Order order) {
        log.info("🔄 Resetting driver search for order: {}", order.getOrderNumber());

        order.setDriverSearchStartedAt(LocalDateTime.now());
        order.setDriverSearchAttempts(0);
        order.setDriverSearchCompleted(false);
        order.setStatus(Order.OrderStatus.READY_FOR_PICKUP);
        orderRepository.save(order);

        log.info("✅ Driver search reset for order: {}", order.getOrderNumber());
    }
}
