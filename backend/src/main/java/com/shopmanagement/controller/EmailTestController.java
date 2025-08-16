package com.shopmanagement.controller;

import com.shopmanagement.service.EmailService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/test/email")
@RequiredArgsConstructor
@CrossOrigin(originPatterns = {"*"}, allowCredentials = "false")
public class EmailTestController {

    private final EmailService emailService;
    
    @PersistenceContext
    private EntityManager entityManager;

    @GetMapping("/simple")
    public ResponseEntity<Map<String, String>> sendTestEmail(@RequestParam String to) {
        try {
            emailService.sendTestEmail(to);
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Test email sent successfully to " + to
            ));
        } catch (Exception e) {
            log.error("Failed to send test email", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to send test email: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/welcome")
    public ResponseEntity<Map<String, String>> sendWelcomeEmail(
            @RequestParam String to,
            @RequestParam String shopOwnerName,
            @RequestParam String username,
            @RequestParam String temporaryPassword,
            @RequestParam String shopName) {
        try {
            emailService.sendShopOwnerWelcomeEmail(to, shopOwnerName, username, temporaryPassword, shopName);
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Welcome email sent successfully to " + to
            ));
        } catch (Exception e) {
            log.error("Failed to send welcome email", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to send welcome email: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/password-reset")
    public ResponseEntity<Map<String, String>> sendPasswordResetEmail(
            @RequestParam String to,
            @RequestParam String username,
            @RequestParam String resetToken) {
        try {
            emailService.sendPasswordResetEmail(to, username, resetToken);
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Password reset email sent successfully to " + to
            ));
        } catch (Exception e) {
            log.error("Failed to send password reset email", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to send password reset email: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/fix-null-track-inventory")
    @Transactional
    public ResponseEntity<Map<String, String>> fixNullTrackInventory() {
        try {
            int updated = entityManager.createQuery("UPDATE ShopProduct sp SET sp.trackInventory = true WHERE sp.trackInventory IS NULL")
                    .executeUpdate();
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Updated " + updated + " shop products with null track_inventory values"
            ));
        } catch (Exception e) {
            log.error("Failed to fix null track_inventory values", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to fix null track_inventory values: " + e.getMessage()
            ));
        }
    }
}