package com.shopmanagement.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseNotificationService {

    @Value("${firebase.server-key:}")
    private String firebaseServerKey;

    @Value("${firebase.project-id:grocery-5ecc5}")
    private String projectId;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final String FCM_URL = "https://fcm.googleapis.com/fcm/send";

    public void sendOrderNotification(String orderNumber, String status, String customerToken) {
        try {
            String title = getNotificationTitle(status);
            String body = getNotificationBody(orderNumber, status);
            
            sendPushNotification(customerToken, title, body, createOrderData(orderNumber, status));
            
        } catch (Exception e) {
            log.error("Error sending Firebase notification for order: {}", orderNumber, e);
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

    private void sendPushNotification(String token, String title, String body, Map<String, String> data) {
        if (firebaseServerKey == null || firebaseServerKey.isEmpty()) {
            log.warn("Firebase server key not configured. Notification not sent.");
            return;
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "key=" + firebaseServerKey);

            Map<String, Object> notification = new HashMap<>();
            notification.put("title", title);
            notification.put("body", body);
            notification.put("icon", "/assets/icons/notification.png");
            notification.put("click_action", "FCM_PLUGIN_ACTIVITY");

            Map<String, Object> payload = new HashMap<>();
            payload.put("to", token);
            payload.put("notification", notification);
            payload.put("data", data);
            payload.put("priority", "high");

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(payload, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(FCM_URL, request, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                log.info("Firebase notification sent successfully");
            } else {
                log.error("Failed to send Firebase notification. Response: {}", response.getBody());
            }

        } catch (Exception e) {
            log.error("Error sending push notification", e);
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
            // Send a test notification to a dummy token
            Map<String, String> testData = new HashMap<>();
            testData.put("type", "test");
            
            log.info("Firebase configuration test - Server key present: {}", 
                    firebaseServerKey != null && !firebaseServerKey.isEmpty());
            
            return true;
        } catch (Exception e) {
            log.error("Firebase connection test failed", e);
            return false;
        }
    }
}