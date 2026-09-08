package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Tells the shop owner (FCM push + web dashboard WebSocket, and for the
 * legacy admin/POS order path also email) that a real, actionable order
 * exists.
 *
 * Deliberately its own bean with no dependency on OrderService or
 * OrderPaymentService: those two already depend on each other in one
 * direction, and both need to call into this - a shared standalone service
 * avoids turning that into a circular dependency.
 *
 * Callers decide WHEN to invoke this. For COD orders that's immediately at
 * creation. For ONLINE_PAYMENT orders it must be deferred until the payment
 * actually clears (see OrderPaymentService.markPaid) - notifying at order
 * creation for an unpaid online order tells the shop owner about work that
 * may never actually happen if the customer abandons or fails checkout.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ShopOrderNotificationService {

    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final FirebaseNotificationService firebaseNotificationService;
    private final EmailService emailService;
    private final SimpMessagingTemplate messagingTemplate;

    public void notifyNewOrder(Order savedOrder) {
        // Resolve everything to plain values now, while the Hibernate session
        // backing savedOrder's lazy associations is still open - some call
        // sites run this from a post-commit hook where that session has
        // already closed, and touching a lazy proxy then throws
        // LazyInitializationException.
        Shop shop = savedOrder.getShop();
        String customerName = savedOrder.getCustomer().getFullName();
        String customerPhone = savedOrder.getCustomer().getMobileNumber();
        List<OrderItem> orderItems = savedOrder.getOrderItems();

        sendFcmToShopOwner(savedOrder, shop, customerName, orderItems);
        sendWebSocketToShopOwner(savedOrder, shop, customerName, customerPhone, orderItems.size());
    }

    /** Same as notifyNewOrder, plus the shop-owner email the legacy order-creation path sends. */
    public void notifyNewOrderWithEmail(Order savedOrder) {
        Shop shop = savedOrder.getShop();
        List<OrderItem> orderItems = savedOrder.getOrderItems();

        try {
            String itemsSummary = orderItems.stream()
                    .map(item -> String.format("%s x%d (₹%.2f)",
                            item.getProductName(), item.getQuantity(), item.getTotalPrice()))
                    .collect(Collectors.joining(", "));

            emailService.sendOrderPlacedNotificationToShop(
                    shop.getOwnerEmail(),
                    shop.getOwnerName(),
                    savedOrder.getOrderNumber(),
                    savedOrder.getCustomer().getFullName(),
                    String.format("₹%.2f", savedOrder.getTotalAmount()),
                    itemsSummary
            );
        } catch (Exception e) {
            log.error("Failed to send order notification email to shop owner", e);
        }

        notifyNewOrder(savedOrder);
    }

    private void sendFcmToShopOwner(Order savedOrder, Shop shop, String customerName, List<OrderItem> orderItems) {
        try {
            log.info("🔔 Attempting to send FCM notification to shop owner: {}", shop.getOwnerEmail());
            Optional<User> shopOwnerOpt = userRepository.findByEmail(shop.getOwnerEmail());
            if (shopOwnerOpt.isEmpty()) {
                log.warn("⚠️ Shop owner user not found for email: {}", shop.getOwnerEmail());
                return;
            }

            User shopOwner = shopOwnerOpt.get();
            List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
            log.info("📱 Found {} active FCM token(s) for shop owner", fcmTokens.size());

            for (UserFcmToken fcmToken : fcmTokens) {
                try {
                    firebaseNotificationService.sendNewOrderNotificationToShopOwner(
                            savedOrder.getOrderNumber(),
                            fcmToken.getFcmToken(),
                            shopOwner.getId(),
                            customerName,
                            savedOrder.getTotalAmount().doubleValue(),
                            orderItems.size()
                    );
                } catch (Exception e) {
                    log.error("❌ Failed to send FCM to device {}: {}", fcmToken.getDeviceType(), e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("❌ Failed to send FCM notification to shop owner", e);
        }
    }

    private void sendWebSocketToShopOwner(Order savedOrder, Shop shop, String customerName,
                                           String customerPhone, int itemCount) {
        final Long orderId = savedOrder.getId();
        final String orderNumber = savedOrder.getOrderNumber();
        final BigDecimal totalAmount = savedOrder.getTotalAmount();
        final String status = savedOrder.getStatus().name();
        final String deliveryType = savedOrder.getDeliveryType() != null ? savedOrder.getDeliveryType().name() : null;
        final Order.PaymentMethod paymentMethod = savedOrder.getPaymentMethod();
        final String createdAt = savedOrder.getCreatedAt().toString();
        final Long shopId = shop.getId();

        Runnable send = () -> {
            try {
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("type", "NEW_ORDER");
                orderData.put("orderId", orderId);
                orderData.put("orderNumber", orderNumber);
                orderData.put("customerName", customerName);
                orderData.put("customerPhone", customerPhone);
                orderData.put("totalAmount", totalAmount);
                orderData.put("itemCount", itemCount);
                orderData.put("status", status);
                orderData.put("deliveryType", deliveryType);
                orderData.put("paymentMethod", paymentMethod);
                orderData.put("createdAt", createdAt);
                orderData.put("timestamp", LocalDateTime.now().toString());

                String destination = "/topic/shop/" + shopId + "/orders";
                messagingTemplate.convertAndSend(destination, orderData);
                log.info("✅ WebSocket notification sent to {} for new order: {}", destination, orderNumber);
            } catch (Exception e) {
                log.error("❌ Error sending WebSocket notification for order {}: {}", orderNumber, e.getMessage());
            }
        };

        try {
            if (TransactionSynchronizationManager.isSynchronizationActive()) {
                TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        send.run();
                    }
                });
            } else {
                send.run();
            }
        } catch (Exception e) {
            log.error("❌ Failed to schedule WebSocket notification to shop", e);
        }
    }
}
