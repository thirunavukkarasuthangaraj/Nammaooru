package com.shopmanagement.controller;

import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.FcmTokenService;
import com.shopmanagement.service.FirebaseNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class FcmTokenController {

    private final UserFcmTokenRepository userFcmTokenRepository;
    private final UserRepository userRepository;
    private final FirebaseNotificationService firebaseNotificationService;
    private final FcmTokenService fcmTokenService;

    /**
     * The authenticated user, or null when the request carries no (valid) JWT.
     * /api/customer/** is permitAll, so the app can hit these endpoints while
     * logged out (e.g. onTokenRefresh before login) - that must be a clean 401,
     * not a stack trace.
     */
    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
            return null;
        }
        return userRepository.findByUsername(auth.getName()).orElse(null);
    }

    private ResponseEntity<?> loginRequired() {
        return ResponseEntity.status(401).body(ApiResponse.error("Login required to register a device token"));
    }

    @PostMapping("/notifications/fcm-token")
    public ResponseEntity<?> updateDeliveryPartnerFcmToken(@RequestBody FcmTokenRequest request) {
        try {
            User user = currentUser();
            if (user == null) return loginRequired();
            log.info("🔔 Updating FCM token for delivery partner: {} (ID: {}, Role: {})",
                    user.getUsername(), user.getId(), user.getRole());

            fcmTokenService.registerToken(user.getId(), request);

            return ResponseEntity.ok(ApiResponse.success("FCM token updated successfully", null));
        } catch (Exception e) {
            log.error("❌ FCM registration API failed for delivery partner", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to update FCM token: " + e.getMessage()));
        }
    }

    @PostMapping("/customer/notifications/fcm-token")
    public ResponseEntity<?> updateFcmToken(@RequestBody FcmTokenRequest request) {
        try {
            User user = currentUser();
            if (user == null) return loginRequired();
            log.info("Updating FCM token for user: {} (ID: {})", user.getUsername(), user.getId());

            fcmTokenService.registerToken(user.getId(), request);

            return ResponseEntity.ok(ApiResponse.success("FCM token updated successfully", null));
        } catch (Exception e) {
            log.error("FCM registration API failed", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to update FCM token: " + e.getMessage()));
        }
    }

    @DeleteMapping("/customer/notifications/fcm-token")
    public ResponseEntity<?> removeFcmToken(@RequestParam String token) {
        try {
            User user = currentUser();
            if (user == null) return loginRequired();

            fcmTokenService.deactivateToken(user.getId(), token);

            return ResponseEntity.ok(ApiResponse.success("FCM token removed successfully", null));
        } catch (Exception e) {
            log.error("Error removing FCM token", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to remove FCM token: " + e.getMessage()));
        }
    }

    @GetMapping("/customer/notifications/test-push")
    public ResponseEntity<?> testPushNotification() {
        try {
            User user = currentUser();
            if (user == null) return loginRequired();
            log.info("Testing push notification for user: {}", user.getUsername());

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
