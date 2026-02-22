package com.shopmanagement.auth.controller;

import com.shopmanagement.auth.service.PasswordResetService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/auth/password")
@RequiredArgsConstructor
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    @PostMapping("/forgot")
    public ResponseEntity<Map<String, String>> forgotPassword(@RequestBody Map<String, String> request) {
        try {
            String usernameOrEmail = request.get("usernameOrEmail");
            
            if (usernameOrEmail == null || usernameOrEmail.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Username or email is required"
                ));
            }
            
            passwordResetService.initiatePasswordReset(usernameOrEmail.trim());
            
            // Always return success to prevent user enumeration attacks
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "If an account with that username or email exists, a password reset link has been sent."
            ));
            
        } catch (Exception e) {
            log.error("Error in forgot password process", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "error",
                "message", "An error occurred. Please try again later."
            ));
        }
    }

    @PostMapping("/validate-token")
    public ResponseEntity<Map<String, Object>> validateResetToken(@RequestBody Map<String, String> request) {
        try {
            String token = request.get("token");
            
            if (token == null || token.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Reset token is required",
                    "valid", false
                ));
            }
            
            boolean isValid = passwordResetService.validateResetToken(token.trim());
            
            if (isValid) {
                return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "Reset token is valid",
                    "valid", true
                ));
            } else {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Reset token is invalid or expired",
                    "valid", false
                ));
            }
            
        } catch (Exception e) {
            log.error("Error validating reset token", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "error",
                "message", "An error occurred. Please try again later.",
                "valid", false
            ));
        }
    }

    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> resetPassword(@RequestBody Map<String, String> request) {
        try {
            String token = request.get("token");
            String newPassword = request.get("newPassword");
            
            if (token == null || token.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Reset token is required"
                ));
            }
            
            if (newPassword == null || newPassword.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "New password is required"
                ));
            }
            
            if (newPassword.length() < 4) {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Password must be at least 4 characters long"
                ));
            }
            
            boolean success = passwordResetService.resetPassword(token.trim(), newPassword);
            
            if (success) {
                return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "Password has been reset successfully"
                ));
            } else {
                return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", "Failed to reset password. Token may be invalid or expired."
                ));
            }
            
        } catch (Exception e) {
            log.error("Error resetting password", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "error",
                "message", "An error occurred. Please try again later."
            ));
        }
    }
}