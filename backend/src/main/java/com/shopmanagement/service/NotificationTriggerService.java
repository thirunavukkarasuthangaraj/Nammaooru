package com.shopmanagement.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationTriggerService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationTriggerService.class);

    @Autowired
    private FirebaseService firebaseService;

    /**
     * Send notification when user login (store FCM token)
     * Called from login controller
     */
    public void onUserLogin(Long userId, String userRole, String fcmToken, String deviceType) {
        try {
            // Store FCM token
            firebaseService.storeFcmToken(userId, fcmToken, deviceType, null);

            // Subscribe to topics
            firebaseService.subscribeUserToTopics(userId, userRole);

            // Send welcome notification
            Map<String, String> data = new HashMap<>();
            data.put("userId", userId.toString());
            data.put("action", "welcome");

            firebaseService.sendNotificationToUser(
                userId,
                "வணக்கம்! Welcome to Namma Ooru! 🙏",
                "You're now connected to your local village delivery network.",
                data,
                "welcome"
            );

            logger.info("Welcome notification sent to user: {}", userId);

        } catch (Exception e) {
            logger.error("Error in onUserLogin notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send notification when order is placed
     */
    public void onOrderPlaced(Long customerId, Long shopOwnerId, String orderId, String shopName) {
        try {
            // Notify customer
            Map<String, String> customerData = new HashMap<>();
            customerData.put("orderId", orderId);
            customerData.put("shopName", shopName);
            customerData.put("action", "order_placed");

            firebaseService.sendNotificationToUser(
                customerId,
                "Order Confirmed! 🎉",
                "Your order from " + shopName + " has been confirmed and is being prepared.",
                customerData,
                "order"
            );

            // Notify shop owner
            Map<String, String> shopData = new HashMap<>();
            shopData.put("orderId", orderId);
            shopData.put("customerId", customerId.toString());
            shopData.put("action", "new_order");

            firebaseService.sendNotificationToUser(
                shopOwnerId,
                "New Order Received! 📦",
                "You have a new order #" + orderId + ". Please start preparing it.",
                shopData,
                "order"
            );

            logger.info("Order placed notifications sent for order: {}", orderId);

        } catch (Exception e) {
            logger.error("Error in onOrderPlaced notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send notification when order is ready for delivery
     */
    public void onOrderReady(Long customerId, String orderId, String shopName) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("orderId", orderId);
            data.put("shopName", shopName);
            data.put("action", "order_ready");

            firebaseService.sendNotificationToUser(
                customerId,
                "Order Ready! ✅",
                "Your order from " + shopName + " is ready for pickup/delivery.",
                data,
                "order"
            );

            // Also notify delivery partners in the area
            firebaseService.sendNotificationToTopic(
                "delivery_partners",
                "Delivery Available! 🚴",
                "New delivery order available from " + shopName,
                data,
                "delivery"
            );

            logger.info("Order ready notifications sent for order: {}", orderId);

        } catch (Exception e) {
            logger.error("Error in onOrderReady notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send notification when order is picked up by delivery partner
     */
    public void onOrderPickedUp(Long customerId, Long deliveryPartnerId, String orderId, String deliveryPartnerName) {
        try {
            // Notify customer
            Map<String, String> customerData = new HashMap<>();
            customerData.put("orderId", orderId);
            customerData.put("deliveryPartnerId", deliveryPartnerId.toString());
            customerData.put("deliveryPartnerName", deliveryPartnerName);
            customerData.put("action", "order_picked_up");

            firebaseService.sendNotificationToUser(
                customerId,
                "Order Picked Up! 🚴",
                deliveryPartnerName + " has picked up your order and is on the way.",
                customerData,
                "delivery"
            );

            // Notify delivery partner
            Map<String, String> deliveryData = new HashMap<>();
            deliveryData.put("orderId", orderId);
            deliveryData.put("customerId", customerId.toString());
            deliveryData.put("action", "delivery_assigned");

            firebaseService.sendNotificationToUser(
                deliveryPartnerId,
                "Delivery Assigned! 📦",
                "You have been assigned delivery for order #" + orderId,
                deliveryData,
                "delivery"
            );

            logger.info("Order picked up notifications sent for order: {}", orderId);

        } catch (Exception e) {
            logger.error("Error in onOrderPickedUp notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send notification when order is delivered
     */
    public void onOrderDelivered(Long customerId, Long shopOwnerId, Long deliveryPartnerId, String orderId) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("orderId", orderId);
            data.put("action", "order_delivered");

            // Notify customer
            firebaseService.sendNotificationToUser(
                customerId,
                "Order Delivered! ✅",
                "Your order #" + orderId + " has been delivered successfully. Enjoy!",
                data,
                "delivery"
            );

            // Notify shop owner
            firebaseService.sendNotificationToUser(
                shopOwnerId,
                "Order Completed! 🎉",
                "Order #" + orderId + " has been delivered successfully.",
                data,
                "order"
            );

            // Notify delivery partner
            firebaseService.sendNotificationToUser(
                deliveryPartnerId,
                "Delivery Completed! ✅",
                "You have successfully delivered order #" + orderId,
                data,
                "delivery"
            );

            logger.info("Order delivered notifications sent for order: {}", orderId);

        } catch (Exception e) {
            logger.error("Error in onOrderDelivered notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send notification when new shop joins the platform
     */
    public void onNewShopJoined(String shopName, String shopType, String area) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("shopName", shopName);
            data.put("shopType", shopType);
            data.put("area", area);
            data.put("action", "new_shop");

            // Notify all customers in the area
            firebaseService.sendNotificationToTopic(
                "customers",
                "New Shop Available! 🏪",
                shopName + " (" + shopType + ") is now delivering in " + area + ". Check it out!",
                data,
                "shop"
            );

            logger.info("New shop notification sent for: {}", shopName);

        } catch (Exception e) {
            logger.error("Error in onNewShopJoined notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send promotional notifications
     */
    public void sendPromotionalNotification(String title, String body, String offerCode, List<Long> targetUserIds) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("offerCode", offerCode);
            data.put("action", "promotion");

            if (targetUserIds != null && !targetUserIds.isEmpty()) {
                // Send to specific users
                firebaseService.sendNotificationToUsers(targetUserIds, title, body, data, "promotion");
            } else {
                // Send to all customers
                firebaseService.sendNotificationToTopic("customers", title, body, data, "promotion");
            }

            logger.info("Promotional notification sent: {}", title);

        } catch (Exception e) {
            logger.error("Error in sendPromotionalNotification: {}", e.getMessage());
        }
    }

    /**
     * Send system announcements
     */
    public void sendSystemAnnouncement(String title, String body, String targetRole) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("action", "announcement");

            String topic = switch (targetRole.toLowerCase()) {
                case "customer" -> "customers";
                case "shop_owner" -> "shop_owners";
                case "delivery_partner" -> "delivery_partners";
                default -> "all_users";
            };

            firebaseService.sendNotificationToTopic(topic, title, body, data, "announcement");

            logger.info("System announcement sent to {}: {}", topic, title);

        } catch (Exception e) {
            logger.error("Error in sendSystemAnnouncement: {}", e.getMessage());
        }
    }

    /**
     * Send payment confirmation notification
     */
    public void onPaymentSuccess(Long customerId, String orderId, Double amount, String paymentMethod) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("orderId", orderId);
            data.put("amount", amount.toString());
            data.put("paymentMethod", paymentMethod);
            data.put("action", "payment_success");

            firebaseService.sendNotificationToUser(
                customerId,
                "Payment Successful! 💳",
                "Payment of ₹" + amount + " for order #" + orderId + " completed successfully.",
                data,
                "payment"
            );

            logger.info("Payment success notification sent for order: {}", orderId);

        } catch (Exception e) {
            logger.error("Error in onPaymentSuccess notification trigger: {}", e.getMessage());
        }
    }

    /**
     * Send low stock alert to shop owner
     */
    public void onLowStockAlert(Long shopOwnerId, String productName, int currentStock) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("productName", productName);
            data.put("currentStock", String.valueOf(currentStock));
            data.put("action", "low_stock");

            firebaseService.sendNotificationToUser(
                shopOwnerId,
                "Low Stock Alert! ⚠️",
                productName + " is running low (only " + currentStock + " left). Please restock soon.",
                data,
                "inventory"
            );

            logger.info("Low stock alert sent for product: {}", productName);

        } catch (Exception e) {
            logger.error("Error in onLowStockAlert notification trigger: {}", e.getMessage());
        }
    }
}