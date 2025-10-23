package com.shopmanagement.controller;

import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.FirebaseService;
import com.shopmanagement.service.JwtService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@Slf4j
public class FirebaseController {

    @Autowired
    private FirebaseService firebaseService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserRepository userRepository;

    // Customer FCM token endpoint removed - handled by FcmTokenController

    /**
     * Store/Update FCM Token for shop owner
     */
    @PostMapping("/shop-owner/notifications/fcm-token")
    public ResponseEntity<Map<String, Object>> updateShopOwnerFcmToken(
            @RequestBody FcmTokenRequest request,
            HttpServletRequest httpRequest) {

        Map<String, Object> response = new HashMap<>();

        try {
            // Get user ID from JWT token
            String token = httpRequest.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
                String username = jwtService.extractUsername(token);

                // Look up user by username
                User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found: " + username));

                Long userId = user.getId();
                log.info("📝 Registering FCM token for shop owner: {} (ID: {})", username, userId);

                firebaseService.storeFcmToken(
                    userId,
                    request.getFcmToken(),
                    request.getDeviceType() != null ? request.getDeviceType() : "android",
                    request.getDeviceId()
                );

                log.info("✅ FCM token registered successfully for shop owner: {} (ID: {})", username, userId);

                // Subscribe to shop owner topics (do this after token is saved)
                try {
                    firebaseService.subscribeUserToTopics(userId, "SHOP_OWNER");
                    log.info("✅ Subscribed shop owner to FCM topics");
                } catch (Exception e) {
                    log.warn("⚠️ Failed to subscribe to topics (non-critical): {}", e.getMessage());
                    // Don't fail the registration if topic subscription fails
                }

                response.put("statusCode", "0000");
                response.put("message", "FCM token stored successfully");
                response.put("data", null);

                return ResponseEntity.ok(response);
            }

            response.put("statusCode", "4001");
            response.put("message", "Invalid authorization token");
            response.put("data", null);
            return ResponseEntity.status(401).body(response);

        } catch (Exception e) {
            response.put("statusCode", "5000");
            response.put("message", "Error storing FCM token: " + e.getMessage());
            response.put("data", null);
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Store/Update FCM Token for delivery partner
     */
    @PostMapping("/delivery-partner/notifications/fcm-token")
    public ResponseEntity<Map<String, Object>> updateDeliveryPartnerFcmToken(
            @RequestBody FcmTokenRequest request,
            HttpServletRequest httpRequest) {

        Map<String, Object> response = new HashMap<>();

        try {
            // Get user ID from JWT token
            String token = httpRequest.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
                String username = jwtService.extractUsername(token);

                // Look up user by username
                User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found: " + username));

                Long userId = user.getId();
                log.info("📝 Registering FCM token for delivery partner: {} (ID: {})", username, userId);

                firebaseService.storeFcmToken(
                    userId,
                    request.getFcmToken(),
                    request.getDeviceType() != null ? request.getDeviceType() : "android",
                    request.getDeviceId()
                );

                log.info("✅ FCM token registered successfully for delivery partner: {} (ID: {})", username, userId);

                // Subscribe to delivery partner topics (do this after token is saved)
                try {
                    firebaseService.subscribeUserToTopics(userId, "DELIVERY_PARTNER");
                    log.info("✅ Subscribed delivery partner to FCM topics");
                } catch (Exception e) {
                    log.warn("⚠️ Failed to subscribe to topics (non-critical): {}", e.getMessage());
                    // Don't fail the registration if topic subscription fails
                }

                response.put("statusCode", "0000");
                response.put("message", "FCM token stored successfully");
                response.put("data", null);

                return ResponseEntity.ok(response);
            }

            response.put("statusCode", "4001");
            response.put("message", "Invalid authorization token");
            response.put("data", null);
            return ResponseEntity.status(401).body(response);

        } catch (Exception e) {
            response.put("statusCode", "5000");
            response.put("message", "Error storing FCM token: " + e.getMessage());
            response.put("data", null);
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Send test notification (for development/testing)
     */
    @PostMapping("/admin/send-test-notification")
    public ResponseEntity<Map<String, Object>> sendTestNotification(
            @RequestParam Long userId,
            @RequestParam String title,
            @RequestParam String body) {

        Map<String, Object> response = new HashMap<>();

        try {
            Map<String, String> data = new HashMap<>();
            data.put("test", "true");

            firebaseService.sendNotificationToUser(userId, title, body, data, "test");

            response.put("statusCode", "0000");
            response.put("message", "Test notification sent successfully");
            response.put("data", null);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("statusCode", "5000");
            response.put("message", "Error sending test notification: " + e.getMessage());
            response.put("data", null);
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Send notification to topic (for admin use)
     */
    @PostMapping("/admin/send-topic-notification")
    public ResponseEntity<Map<String, Object>> sendTopicNotification(
            @RequestParam String topic,
            @RequestParam String title,
            @RequestParam String body) {

        Map<String, Object> response = new HashMap<>();

        try {
            Map<String, String> data = new HashMap<>();
            data.put("topic", topic);

            firebaseService.sendNotificationToTopic(topic, title, body, data, "announcement");

            response.put("statusCode", "0000");
            response.put("message", "Topic notification sent successfully");
            response.put("data", null);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("statusCode", "5000");
            response.put("message", "Error sending topic notification: " + e.getMessage());
            response.put("data", null);
            return ResponseEntity.status(500).body(response);
        }
    }
}