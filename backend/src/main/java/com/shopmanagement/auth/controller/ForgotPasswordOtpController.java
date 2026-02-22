package com.shopmanagement.auth.controller;

import com.shopmanagement.auth.service.PasswordResetOtpService;
import com.shopmanagement.common.constants.ResponseConstants;
import com.shopmanagement.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.WebRequest;

import java.time.LocalDateTime;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/auth/forgot-password")
@RequiredArgsConstructor
public class ForgotPasswordOtpController {

    private final PasswordResetOtpService passwordResetOtpService;

    @PostMapping("/send-otp")
    public ResponseEntity<ApiResponse<Void>> sendPasswordResetOtp(@RequestBody Map<String, String> request, WebRequest webRequest) {
        try {
            // Support both email and mobile number (identifier)
            String identifier = request.get("identifier") != null ? request.get("identifier") : request.get("email");

            if (identifier == null || identifier.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("Email or mobile number is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            boolean success = passwordResetOtpService.sendPasswordResetOtp(identifier.trim());

            if (success) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.SUCCESS)
                        .message("OTP has been sent successfully")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            } else {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.GENERAL_ERROR)
                        .message("Too many requests. Please try again later")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

        } catch (Exception e) {
            log.error("Error sending password reset OTP", e);
            ApiResponse<Void> response = ApiResponse.<Void>builder()
                    .statusCode(ResponseConstants.GENERAL_ERROR)
                    .message("An error occurred. Please try again later")
                    .timestamp(LocalDateTime.now())
                    .path(webRequest.getDescription(false).replace("uri=", ""))
                    .build();
            return ResponseEntity.ok(response);
        }
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<Void>> verifyPasswordResetOtp(@RequestBody Map<String, String> request, WebRequest webRequest) {
        try {
            // Support both email and mobile number (identifier)
            String identifier = request.get("identifier") != null ? request.get("identifier") : request.get("email");
            String otp = request.get("otp");

            if (identifier == null || identifier.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("Email or mobile number is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            if (otp == null || otp.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("OTP is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            boolean isValid = passwordResetOtpService.verifyPasswordResetOtp(identifier.trim(), otp.trim());

            if (isValid) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.SUCCESS)
                        .message("OTP verified successfully")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            } else {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.INVALID_CREDENTIALS)
                        .message("Invalid or expired OTP")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

        } catch (Exception e) {
            log.error("Error verifying password reset OTP", e);
            ApiResponse<Void> response = ApiResponse.<Void>builder()
                    .statusCode(ResponseConstants.GENERAL_ERROR)
                    .message("An error occurred. Please try again later")
                    .timestamp(LocalDateTime.now())
                    .path(webRequest.getDescription(false).replace("uri=", ""))
                    .build();
            return ResponseEntity.ok(response);
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPasswordWithOtp(@RequestBody Map<String, String> request, WebRequest webRequest) {
        try {
            // Support both email and mobile number (identifier)
            String identifier = request.get("identifier") != null ? request.get("identifier") : request.get("email");
            String otp = request.get("otp");
            String newPassword = request.get("newPassword");

            if (identifier == null || identifier.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("Email or mobile number is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            if (otp == null || otp.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("OTP is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            if (newPassword == null || newPassword.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("New password is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            if (newPassword.length() < 4) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("Password must be at least 4 characters long")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            boolean success = passwordResetOtpService.resetPasswordWithOtp(
                identifier.trim(), otp.trim(), newPassword);

            if (success) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.SUCCESS)
                        .message("Password has been reset successfully")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            } else {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.GENERAL_ERROR)
                        .message("Failed to reset password. Please verify your OTP and try again")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

        } catch (Exception e) {
            log.error("Error resetting password with OTP", e);
            ApiResponse<Void> response = ApiResponse.<Void>builder()
                    .statusCode(ResponseConstants.GENERAL_ERROR)
                    .message("An error occurred. Please try again later")
                    .timestamp(LocalDateTime.now())
                    .path(webRequest.getDescription(false).replace("uri=", ""))
                    .build();
            return ResponseEntity.ok(response);
        }
    }

    @PostMapping("/resend-otp")
    public ResponseEntity<ApiResponse<Void>> resendPasswordResetOtp(@RequestBody Map<String, String> request, WebRequest webRequest) {
        try {
            // Support both email and mobile number (identifier)
            String identifier = request.get("identifier") != null ? request.get("identifier") : request.get("email");

            if (identifier == null || identifier.trim().isEmpty()) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.VALIDATION_ERROR)
                        .message("Email or mobile number is required")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

            boolean success = passwordResetOtpService.resendPasswordResetOtp(identifier.trim());

            if (success) {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.SUCCESS)
                        .message("OTP has been resent successfully")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            } else {
                ApiResponse<Void> response = ApiResponse.<Void>builder()
                        .statusCode(ResponseConstants.GENERAL_ERROR)
                        .message("Failed to resend OTP. Please try again later")
                        .timestamp(LocalDateTime.now())
                        .path(webRequest.getDescription(false).replace("uri=", ""))
                        .build();
                return ResponseEntity.ok(response);
            }

        } catch (Exception e) {
            log.error("Error resending password reset OTP", e);
            ApiResponse<Void> response = ApiResponse.<Void>builder()
                    .statusCode(ResponseConstants.GENERAL_ERROR)
                    .message("An error occurred. Please try again later")
                    .timestamp(LocalDateTime.now())
                    .path(webRequest.getDescription(false).replace("uri=", ""))
                    .build();
            return ResponseEntity.ok(response);
        }
    }

    private boolean isValidEmail(String email) {
        return email != null && email.matches("^[A-Za-z0-9+_.-]+@(.+)$");
    }
}