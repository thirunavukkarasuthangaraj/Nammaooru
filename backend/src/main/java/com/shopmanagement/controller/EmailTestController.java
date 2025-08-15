package com.shopmanagement.controller;

import com.shopmanagement.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/test/email")
@RequiredArgsConstructor
@CrossOrigin(originPatterns = {"http://localhost:*", "http://127.0.0.1:*"}, allowCredentials = "false")
public class EmailTestController {

    private final EmailService emailService;

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
}