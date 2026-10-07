package com.shopmanagement.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.ApnsConfig;
import com.google.firebase.messaging.ApnsFcmOptions;
import com.google.firebase.messaging.Aps;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.NotificationRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseNotificationService {

    private final NotificationRepository notificationRepository;
    private final CustomerRepository customerRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;

    public void sendOrderNotification(String orderNumber, String status, String customerToken, Long customerId) {
        log.info("🚀 FirebaseNotificationService: Preparing notification for order {} with status {}", orderNumber, status);

        String title = getNotificationTitle(status);
        String body = getNotificationBody(orderNumber, status);

        log.info("📄 Notification details - Title: '{}', Body: '{}'", title, body);
        log.info("🎯 Target FCM token: {}...", customerToken.substring(0, Math.min(50, customerToken.length())));

        try {
            // Send push notification - this can throw RuntimeException on failure
            sendPushNotification(customerToken, title, body, createOrderData(orderNumber, status));

            // Save notification history only on success
            saveNotificationHistory(customerId, title, body, "ORDER_UPDATE", orderNumber);

            log.info("✅ Firebase notification processing completed for order: {}", orderNumber);
        } catch (Exception e) {
            log.error("❌ Error sending Firebase notification for order: {}", orderNumber, e);
            // Re-throw to let caller know notification failed (for fallback handling)
            throw new RuntimeException("Failed to send push notification for order: " + orderNumber, e);
        }
    }

    public void sendDeliveryNotification(String orderNumber, String message, String customerToken) {
        try {
            String title = "Delivery Update 🚚";
            String body = String.format("Order %s: %s", orderNumber, message);
            
            sendPushNotification(customerToken, title, body, createDeliveryData(orderNumber));
            
        } catch (Exception e) {
            log.error("Error sending delivery notification for order: {}", orderNumber, e);
        }
    }

    public boolean sendPromotionalNotification(String title, String message, String customerToken) {
        return sendPromotionalNotification(title, message, customerToken, null);
    }

    /**
     * @return true when FCM accepted the message; false when it failed (dead
     *         tokens are deactivated as a side effect, see sendPushNotification).
     */
    public boolean sendPromotionalNotification(String title, String message, String customerToken, String imageUrl) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("type", "promotion");
            data.put("timestamp", String.valueOf(System.currentTimeMillis()));
            if (imageUrl != null && !imageUrl.isEmpty()) {
                data.put("imageUrl", imageUrl);
            }

            sendPushNotification(customerToken, title, message, data, imageUrl);
            return true;

        } catch (Exception e) {
            log.error("Error sending promotional notification: {}", rootMessage(e));
            return false;
        }
    }

    public boolean sendNotificationWithData(String title, String message, String token, Map<String, String> data) {
        return sendNotificationWithData(title, message, token, data, null);
    }

    /**
     * @return true when FCM accepted the message; false when it failed (dead
     *         tokens are deactivated as a side effect, see sendPushNotification).
     */
    public boolean sendNotificationWithData(String title, String message, String token, Map<String, String> data, String imageUrl) {
        try {
            if (data == null) {
                data = new HashMap<>();
            } else {
                // Callers may share one map across many tokens; never mutate theirs
                data = new HashMap<>(data);
            }
            if (!data.containsKey("timestamp")) {
                data.put("timestamp", String.valueOf(System.currentTimeMillis()));
            }
            if (imageUrl != null && !imageUrl.isEmpty()) {
                data.put("imageUrl", imageUrl);
            }
            sendPushNotification(token, title, message, data, imageUrl);
            return true;
        } catch (Exception e) {
            log.error("Error sending notification with data: {}", rootMessage(e));
            return false;
        }
    }

    private static String rootMessage(Throwable t) {
        Throwable cur = t;
        while (cur.getCause() != null && cur.getCause() != cur) {
            cur = cur.getCause();
        }
        return cur.getClass().getSimpleName() + ": " + cur.getMessage();
    }

    /**
     * Send order assignment notification to delivery partner
     */
    public void sendOrderAssignmentNotificationToDriver(String orderNumber, String driverToken, Long driverId, String shopName, String deliveryAddress, Double deliveryFee) {
        try {
            log.info("🚀 Preparing order assignment notification for delivery partner. Order: {}", orderNumber);

            String title = "New Delivery Assigned! 🚚";
            String body = String.format("Order %s from %s - Delivery Fee: ₹%.2f",
                orderNumber, shopName, deliveryFee);

            log.info("📄 Driver Notification - Title: '{}', Body: '{}'", title, body);
            log.info("🎯 Target FCM token: {}...", driverToken.substring(0, Math.min(50, driverToken.length())));

            Map<String, String> data = new HashMap<>();
            data.put("type", "ORDER_ASSIGNED");  // Driver app background handler listens for this
            data.put("orderNumber", orderNumber);
            data.put("shopName", shopName);
            data.put("deliveryAddress", deliveryAddress);
            data.put("deliveryFee", String.valueOf(deliveryFee));
            data.put("timestamp", String.valueOf(System.currentTimeMillis()));

            // Send push notification
            sendPushNotification(driverToken, title, body, data);

            log.info("✅ Order assignment notification sent successfully to driver for order: {}", orderNumber);

        } catch (Exception e) {
            log.error("❌ Error sending order assignment notification to driver for order: {}", orderNumber, e);
        }
    }

    /**
     * Send new order notification to shop owner
     */
    public void sendNewOrderNotificationToShopOwner(String orderNumber, String shopOwnerToken, Long shopOwnerId, String customerName, Double totalAmount, int itemCount) {
        try {
            log.info("🚀 Preparing new order notification for shop owner. Order: {}", orderNumber);

            String title = "New Order Received! 🔔";
            String body = String.format("Order %s from %s - %d items - ₹%.2f",
                orderNumber, customerName, itemCount, totalAmount);

            log.info("📄 Shop Owner Notification - Title: '{}', Body: '{}'", title, body);
            log.info("🎯 Target FCM token: {}...", shopOwnerToken.substring(0, Math.min(50, shopOwnerToken.length())));

            Map<String, String> data = new HashMap<>();
            data.put("type", "new_order");
            data.put("orderNumber", orderNumber);
            data.put("customerName", customerName);
            data.put("totalAmount", String.valueOf(totalAmount));
            data.put("itemCount", String.valueOf(itemCount));
            data.put("timestamp", String.valueOf(System.currentTimeMillis()));

            // Send push notification
            sendPushNotification(shopOwnerToken, title, body, data);

            log.info("✅ New order notification sent successfully to shop owner for order: {}", orderNumber);

        } catch (Exception e) {
            log.error("❌ Error sending new order notification to shop owner for order: {}", orderNumber, e);
        }
    }

    private void sendPushNotification(String token, String title, String body, Map<String, String> data) throws FirebaseMessagingException {
        sendPushNotification(token, title, body, data, null);
    }

    private void sendPushNotification(String token, String title, String body, Map<String, String> data, String imageUrl) throws FirebaseMessagingException {
        try {
            log.info("📡 Building Firebase message...");

            // Determine sound file based on notification type
            String soundFile = determineSoundFile(data.get("type"), data.get("status"));

            // Create notification with image support
            Notification.Builder notificationBuilder = Notification.builder()
                    .setTitle(title)
                    .setBody(body);

            boolean hasImage = imageUrl != null && !imageUrl.isEmpty();

            // Add image to notification if provided
            if (hasImage) {
                notificationBuilder.setImage(imageUrl);
                log.info("🖼️ Adding image to notification: {}", imageUrl);
            }

            Notification notification = notificationBuilder.build();

            // Add sound to data payload for Flutter to handle
            data.put("sound", soundFile);
            data.put("playSound", "true");

            // Create message
            Message.Builder messageBuilder = Message.builder()
                    .setToken(token)
                    .setNotification(notification)
                    .putAllData(data);

            if (hasImage) {
                // Android shows the picture only when it is on the AndroidNotification
                // (the top-level Notification.image alone is ignored by many devices);
                // iOS needs mutable-content + fcm_options.image for the service extension.
                messageBuilder
                        .setAndroidConfig(AndroidConfig.builder()
                                .setNotification(AndroidNotification.builder()
                                        .setImage(imageUrl)
                                        .build())
                                .build())
                        .setApnsConfig(ApnsConfig.builder()
                                .setAps(Aps.builder().setMutableContent(true).build())
                                .setFcmOptions(ApnsFcmOptions.builder().setImage(imageUrl).build())
                                .build());
            }

            Message message = messageBuilder.build();

            log.info("📤 Sending message to Firebase Cloud Messaging...");

            // Send message using Firebase Admin SDK
            String response = FirebaseMessaging.getInstance().send(message);

            log.info("🎉 Firebase notification sent successfully! Message ID: {}", response);
            log.info("📱 Notification should now appear on the device");

        } catch (FirebaseMessagingException e) {
            if (isDeadTokenError(e)) {
                // Token no longer belongs to an installed app (uninstall, data clear,
                // rotation). Firebase returns "NotRegistered"/UNREGISTERED; the row must
                // be deactivated or every future push to this user silently dies here.
                log.warn("🔄 FCM token is dead ({} / {}). Deactivating token: {}...",
                        e.getMessagingErrorCode(), e.getMessage(),
                        token.substring(0, Math.min(30, token.length())));
                deactivateInvalidToken(token);
            } else {
                log.error("❌ Error sending push notification via Firebase Admin SDK (code {}): {}",
                        e.getMessagingErrorCode(), e.getMessage());
            }
            throw new RuntimeException(e);
        } catch (Exception e) {
            log.error("❌ Error sending push notification via Firebase Admin SDK", e);
            log.error("💡 Check Firebase configuration, FCM token validity, and internet connection");
            throw new RuntimeException(e);
        }
    }

    /**
     * True when FCM says the registration token itself is unusable, so the row
     * should be deactivated. Covers the v1 error codes (UNREGISTERED, and
     * INVALID_ARGUMENT which FCM returns for malformed/foreign tokens) plus the
     * legacy message strings ("NotRegistered", "registration-token-not-registered").
     */
    static boolean isDeadTokenError(FirebaseMessagingException e) {
        MessagingErrorCode code = e.getMessagingErrorCode();
        if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
            return true;
        }
        String msg = e.getMessage();
        if (msg == null) return false;
        String lower = msg.toLowerCase();
        return lower.contains("notregistered")
                || lower.contains("registration-token-not-registered")
                || lower.contains("unregistered")
                || lower.contains("requested entity was not found");
    }

    private String getNotificationTitle(String status) {
        return switch (status.toUpperCase()) {
            case "PENDING" -> "Order Placed Successfully! 🎉";
            case "CONFIRMED" -> "Order Confirmed! ✅";
            case "PREPARING" -> "Order Being Prepared 🛍️";
            case "READY" -> "Order Ready! 📦";
            case "READY_FOR_PICKUP" -> "Ready for Pickup! 🚚";
            case "OUT_FOR_DELIVERY" -> "Out for Delivery! 🛵";
            case "DELIVERED" -> "Order Delivered! ✅";
            case "COMPLETED" -> "Order Completed! 🎊";
            case "CANCELLED" -> "Order Cancelled ❌";
            case "REFUNDED" -> "Order Refunded 💰";
            case "SELF_PICKUP_COLLECTED" -> "Order Collected! 📦";
            case "DRIVER_ACCEPTED" -> "Driver Accepted! 🚚";
            case "ORDER_ASSIGNED" -> "New Delivery Assigned! 🚚";
            case "ORDER_COLLECTED" -> "Order Collected by Driver! 📦";
            case "RETURNING_TO_SHOP" -> "Order Returning to Shop 🔙";
            case "RETURNED_TO_SHOP" -> "Order Returned to Shop 📦";
            case "NO_DRIVER_AVAILABLE" -> "No Driver Available 😔";
            case "NO_DRIVER_CUSTOMER" -> "Delivery Delayed ⏳";
            case "SEARCHING_DRIVER" -> "Searching for Driver... 🔍";
            default -> "Order Update 📋";
        };
    }

    private String getNotificationBody(String orderNumber, String status) {
        return switch (status.toUpperCase()) {
            case "PENDING" -> String.format("Your order %s has been placed successfully and is awaiting shop confirmation.", orderNumber);
            case "CONFIRMED" -> String.format("Your order %s has been confirmed and will be prepared soon.", orderNumber);
            case "PREPARING" -> String.format("Your order %s is being prepared by the shop.", orderNumber);
            case "READY" -> String.format("Your order %s is ready at the shop!", orderNumber);
            case "READY_FOR_PICKUP" -> String.format("Your order %s is ready and a delivery partner has been assigned!", orderNumber);
            case "OUT_FOR_DELIVERY" -> String.format("Your order %s is on its way to you!", orderNumber);
            case "DELIVERED" -> String.format("Your order %s has been delivered successfully. Thank you for shopping with us!", orderNumber);
            case "COMPLETED" -> String.format("Your order %s is now completed. Thank you for choosing us!", orderNumber);
            case "CANCELLED" -> String.format("Your order %s has been cancelled.", orderNumber);
            case "REFUNDED" -> String.format("Your order %s has been refunded. The amount will be credited to your account shortly.", orderNumber);
            case "SELF_PICKUP_COLLECTED" -> String.format("You have collected your order %s. Thank you for shopping with us!", orderNumber);
            case "DRIVER_ACCEPTED" -> String.format("A delivery partner has accepted your order %s and will pick it up soon!", orderNumber);
            case "ORDER_ASSIGNED" -> String.format("New delivery order %s has been assigned to you. Please accept it!", orderNumber);
            case "ORDER_COLLECTED" -> String.format("Order %s has been collected by the delivery partner.", orderNumber);
            case "RETURNING_TO_SHOP" -> String.format("Order %s is being returned to shop by driver.", orderNumber);
            case "RETURNED_TO_SHOP" -> String.format("Order %s has been returned to shop. Please verify and collect products.", orderNumber);
            case "NO_DRIVER_AVAILABLE" -> String.format("No delivery partner available for order %s. Please try again later.", orderNumber);
            case "NO_DRIVER_CUSTOMER" -> String.format("Sorry! We're having trouble finding a delivery partner for your order %s. The shop will arrange delivery soon. Thank you for your patience!", orderNumber);
            case "SEARCHING_DRIVER" -> String.format("Searching for delivery partner for order %s...", orderNumber);
            default -> String.format("Status update for your order %s", orderNumber);
        };
    }

    private Map<String, String> createOrderData(String orderNumber, String status) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "order_update");
        data.put("orderNumber", orderNumber);
        data.put("status", status);
        data.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return data;
    }

    private Map<String, String> createDeliveryData(String orderNumber) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "delivery_update");
        data.put("orderNumber", orderNumber);
        data.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return data;
    }

    // Method to test Firebase connectivity
    public boolean testFirebaseConnection() {
        try {
            // Test Firebase Admin SDK connection
            FirebaseMessaging messaging = FirebaseMessaging.getInstance();
            log.info("Firebase Admin SDK connection test successful");
            return true;
        } catch (Exception e) {
            log.error("Firebase Admin SDK connection test failed", e);
            return false;
        }
    }

    private String determineSoundFile(String type, String status) {
        // Determine which sound file to play based on notification type
        if (type == null) return "default";

        return switch (type) {
            case "new_order" -> "new_order.mp3";  // For shop owners receiving new orders
            case "order_assignment", "ORDER_ASSIGNED" -> "new_order.mp3";  // For delivery partners receiving assignment
            case "order_update" -> {
                if (status != null) {
                    yield switch (status.toUpperCase()) {
                        case "PENDING", "CONFIRMED", "DRIVER_ACCEPTED" -> "new_order.mp3";
                        case "PREPARING", "READY", "READY_FOR_PICKUP" -> "message_received.mp3";
                        case "OUT_FOR_DELIVERY" -> "new_order.mp3";
                        case "DELIVERED", "COMPLETED", "SELF_PICKUP_COLLECTED" -> "success_chime.mp3";
                        case "CANCELLED", "REFUNDED" -> "order_cancelled.mp3";
                        default -> "message_received.mp3";
                    };
                }
                yield "new_order.mp3";
            }
            case "delivery_update" -> "message_received.mp3";
            case "payment" -> "payment_received.mp3";
            case "promotion" -> "message_received.mp3";
            default -> "default";
        };
    }

    private void saveNotificationHistory(Long customerId, String title, String body, String type, String orderNumber) {
        try {
            log.info("💾 Saving notification history for customer {} and order {}", customerId, orderNumber);

            com.shopmanagement.entity.Notification notification = com.shopmanagement.entity.Notification.builder()
                    .title(title)
                    .message(body)
                    .type(com.shopmanagement.entity.Notification.NotificationType.ORDER)
                    .priority(com.shopmanagement.entity.Notification.NotificationPriority.MEDIUM)
                    .recipientId(customerId)
                    .recipientType(com.shopmanagement.entity.Notification.RecipientType.CUSTOMER)
                    .status(com.shopmanagement.entity.Notification.NotificationStatus.UNREAD)
                    .metadata("{\"orderNumber\":\"" + orderNumber + "\",\"type\":\"" + type + "\"}")
                    .isPushSent(true)
                    .build();

            notificationRepository.save(notification);
            log.info("✅ Notification history saved successfully for customer {} and order {}", customerId, orderNumber);

        } catch (Exception e) {
            log.error("❌ Error saving notification history for customer {} and order {}", customerId, orderNumber, e);
        }
    }

    /**
     * Deactivate an invalid FCM token so it won't be used again
     */
    private void deactivateInvalidToken(String fcmToken) {
        try {
            // A token can have rows for multiple users (previous logins on the same
            // device); an Optional lookup would throw NonUniqueResultException here.
            for (UserFcmToken token : userFcmTokenRepository.findAllByFcmToken(fcmToken)) {
                if (Boolean.TRUE.equals(token.getIsActive())) {
                    token.setIsActive(false);
                    userFcmTokenRepository.save(token);
                    log.info("🗑️ Deactivated invalid FCM token for user ID: {}", token.getUserId());
                }
            }
        } catch (Exception e) {
            log.error("❌ Error deactivating invalid FCM token", e);
        }
    }
}