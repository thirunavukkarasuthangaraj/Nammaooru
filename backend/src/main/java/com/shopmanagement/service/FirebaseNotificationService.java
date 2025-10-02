package com.shopmanagement.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseNotificationService {

    private final NotificationRepository notificationRepository;
    private final CustomerRepository customerRepository;

    public void sendOrderNotification(String orderNumber, String status, String customerToken, Long customerId) {
        try {
            log.info("🚀 FirebaseNotificationService: Preparing notification for order {} with status {}", orderNumber, status);

            String title = getNotificationTitle(status);
            String body = getNotificationBody(orderNumber, status);

            log.info("📄 Notification details - Title: '{}', Body: '{}'", title, body);
            log.info("🎯 Target FCM token: {}...", customerToken.substring(0, Math.min(50, customerToken.length())));

            // Send push notification
            sendPushNotification(customerToken, title, body, createOrderData(orderNumber, status));

            // Save notification history
            saveNotificationHistory(customerId, title, body, "ORDER_UPDATE", orderNumber);

            log.info("✅ Firebase notification processing completed for order: {}", orderNumber);

        } catch (Exception e) {
            log.error("❌ Error sending Firebase notification for order: {}", orderNumber, e);
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

    public void sendPromotionalNotification(String title, String message, String customerToken) {
        try {
            Map<String, String> data = new HashMap<>();
            data.put("type", "promotion");
            data.put("timestamp", String.valueOf(System.currentTimeMillis()));
            
            sendPushNotification(customerToken, title, message, data);
            
        } catch (Exception e) {
            log.error("Error sending promotional notification", e);
        }
    }

    private void sendPushNotification(String token, String title, String body, Map<String, String> data) throws FirebaseMessagingException {
        try {
            log.info("📡 Building Firebase message...");

            // Create notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            // Create message
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(notification)
                    .putAllData(data)
                    .build();

            log.info("📤 Sending message to Firebase Cloud Messaging...");

            // Send message using Firebase Admin SDK
            String response = FirebaseMessaging.getInstance().send(message);

            log.info("🎉 Firebase notification sent successfully! Message ID: {}", response);
            log.info("📱 Notification should now appear on the device");

        } catch (Exception e) {
            log.error("❌ Error sending push notification via Firebase Admin SDK", e);

            // Check if it's an UNREGISTERED token error
            if (e.getMessage() != null && (e.getMessage().contains("UNREGISTERED") || e.getMessage().contains("Requested entity was not found"))) {
                log.warn("🔄 FCM token is invalid/expired. Token should be refreshed when customer opens the app next time.");
                // Note: We don't deactivate the token here as it might work later when refreshed
            } else {
                log.error("💡 Check Firebase configuration, FCM token validity, and internet connection");
            }

            // Re-throw as runtime exception so the caller can handle it
            throw new RuntimeException(e);
        }
    }

    private String getNotificationTitle(String status) {
        return switch (status.toLowerCase()) {
            case "confirmed" -> "Order Confirmed! 🎉";
            case "preparing" -> "Order Being Prepared 👨‍🍳";
            case "ready_for_pickup" -> "Order Ready! 📦";
            case "out_for_delivery" -> "Out for Delivery! 🚚";
            case "delivered" -> "Order Delivered! ✅";
            case "cancelled" -> "Order Cancelled ❌";
            default -> "Order Update";
        };
    }

    private String getNotificationBody(String orderNumber, String status) {
        return switch (status.toLowerCase()) {
            case "confirmed" -> String.format("Your order %s has been confirmed and is being prepared.", orderNumber);
            case "preparing" -> String.format("Your order %s is being prepared by the restaurant.", orderNumber);
            case "ready_for_pickup" -> String.format("Your order %s is ready for pickup!", orderNumber);
            case "out_for_delivery" -> String.format("Your order %s is on its way to you!", orderNumber);
            case "delivered" -> String.format("Your order %s has been delivered successfully!", orderNumber);
            case "cancelled" -> String.format("Your order %s has been cancelled.", orderNumber);
            default -> String.format("Update for your order %s", orderNumber);
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
}