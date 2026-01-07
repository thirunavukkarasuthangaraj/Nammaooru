package com.shopmanagement.controller;

import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.FirebaseNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Optional;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class FcmTokenController {

    private final UserFcmTokenRepository userFcmTokenRepository;
    private final UserRepository userRepository;
    private final FirebaseNotificationService firebaseNotificationService;

    @PostMapping("/notifications/fcm-token")
    public ResponseEntity<?> updateDeliveryPartnerFcmToken(@RequestBody FcmTokenRequest request) {
        try {
            // Get current user (delivery partner)
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();

            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            log.info("🔔 Updating FCM token for delivery partner: {} (ID: {}, Role: {})", username, user.getId(), user.getRole());

            // Check if token already exists for this user
            Optional<UserFcmToken> existingToken = userFcmTokenRepository
                    .findByUserIdAndFcmToken(user.getId(), request.getFcmToken());

            UserFcmToken fcmToken;
            if (existingToken.isPresent()) {
                // Update existing token
                fcmToken = existingToken.get();
                fcmToken.setIsActive(true);
                fcmToken.setUpdatedAt(LocalDateTime.now());
                if (request.getDeviceType() != null) {
                    fcmToken.setDeviceType(request.getDeviceType());
                }
                if (request.getDeviceId() != null) {
                    fcmToken.setDeviceId(request.getDeviceId());
                }
                log.info("✅ Updated existing FCM token for delivery partner: {}", user.getId());
            } else {
                // Deactivate old tokens for the same device if deviceId is provided
                if (request.getDeviceId() != null) {
                    userFcmTokenRepository.findByUserIdAndIsActiveTrue(user.getId())
                            .stream()
                            .filter(token -> request.getDeviceId().equals(token.getDeviceId()))
                            .forEach(token -> {
                                token.setIsActive(false);
                                userFcmTokenRepository.save(token);
                            });
                }

                // Create new token
                fcmToken = new UserFcmToken();
                fcmToken.setUserId(user.getId());
                fcmToken.setFcmToken(request.getFcmToken());
                fcmToken.setDeviceType(request.getDeviceType() != null ? request.getDeviceType() : "android");
                fcmToken.setDeviceId(request.getDeviceId());
                fcmToken.setIsActive(true);
                log.info("✅ Created new FCM token for delivery partner: {}", user.getId());
            }

            userFcmTokenRepository.save(fcmToken);

            log.info("🎉 FCM token saved successfully for delivery partner: {} (ID: {})", username, user.getId());

            return ResponseEntity.ok(ApiResponse.success("FCM token updated successfully", null));
        } catch (Exception e) {
            log.error("❌ Error updating FCM token for delivery partner", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to update FCM token: " + e.getMessage()));
        }
    }

    @PostMapping("/customer/notifications/fcm-token")
    public ResponseEntity<?> updateFcmToken(@RequestBody FcmTokenRequest request) {
        try {
            // Get current user
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();

            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            log.info("Updating FCM token for user: {} (ID: {})", username, user.getId());

            // Check if token already exists for this user
            Optional<UserFcmToken> existingToken = userFcmTokenRepository
                    .findByUserIdAndFcmToken(user.getId(), request.getFcmToken());

            UserFcmToken fcmToken;
            if (existingToken.isPresent()) {
                // Update existing token
                fcmToken = existingToken.get();
                fcmToken.setIsActive(true);
                fcmToken.setUpdatedAt(LocalDateTime.now());
                if (request.getDeviceType() != null) {
                    fcmToken.setDeviceType(request.getDeviceType());
                }
                if (request.getDeviceId() != null) {
                    fcmToken.setDeviceId(request.getDeviceId());
                }
            } else {
                // Deactivate old tokens for the same device if deviceId is provided
                if (request.getDeviceId() != null) {
                    userFcmTokenRepository.findByUserIdAndIsActiveTrue(user.getId())
                            .stream()
                            .filter(token -> request.getDeviceId().equals(token.getDeviceId()))
                            .forEach(token -> {
                                token.setIsActive(false);
                                userFcmTokenRepository.save(token);
                            });
                }

                // Create new token
                fcmToken = new UserFcmToken();
                fcmToken.setUserId(user.getId());
                fcmToken.setFcmToken(request.getFcmToken());
                fcmToken.setDeviceType(request.getDeviceType() != null ? request.getDeviceType() : "android");
                fcmToken.setDeviceId(request.getDeviceId());
                fcmToken.setIsActive(true);
            }

            userFcmTokenRepository.save(fcmToken);

            log.info("FCM token saved successfully for user: {}", user.getId());

            return ResponseEntity.ok(ApiResponse.success("FCM token updated successfully", null));
        } catch (Exception e) {
            log.error("Error updating FCM token", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to update FCM token: " + e.getMessage()));
        }
    }

    @DeleteMapping("/customer/notifications/fcm-token")
    public ResponseEntity<?> removeFcmToken(@RequestParam String token) {
        try {
            // Get current user
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();

            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Deactivate the token
            Optional<UserFcmToken> fcmToken = userFcmTokenRepository
                    .findByUserIdAndFcmToken(user.getId(), token);

            if (fcmToken.isPresent()) {
                fcmToken.get().setIsActive(false);
                userFcmTokenRepository.save(fcmToken.get());
                log.info("FCM token deactivated for user: {}", user.getId());
            }

            return ResponseEntity.ok(ApiResponse.success("FCM token removed successfully", null));
        } catch (Exception e) {
            log.error("Error removing FCM token", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to remove FCM token: " + e.getMessage()));
        }
    }

    @GetMapping("/customer/notifications/test-push")
    public ResponseEntity<?> testPushNotification() {
        try {
            // Get current user
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();

            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            log.info("Testing push notification for user: {}", username);

            // Get FCM token for the user
            Optional<UserFcmToken> fcmToken = userFcmTokenRepository.findByUserIdAndIsActiveTrue(user.getId())
                    .stream()
                    .findFirst();

            if (fcmToken.isPresent()) {
                firebaseNotificationService.sendOrderNotification(
                        "TEST-001",
                        "CONFIRMED",
                        fcmToken.get().getFcmToken(),
                        1L // Test customer ID
                );
                return ResponseEntity.ok(ApiResponse.success("Test notification sent successfully", null));
            } else {
                return ResponseEntity.ok(ApiResponse.error("No FCM token found for user"));
            }
        } catch (Exception e) {
            log.error("Error testing push notification", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to test notification: " + e.getMessage()));
        }
    }
}