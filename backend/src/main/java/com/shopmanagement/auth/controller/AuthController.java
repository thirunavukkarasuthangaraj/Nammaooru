package com.shopmanagement.auth.controller;

import com.shopmanagement.common.constants.ResponseConstants;
import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.dto.auth.ChangePasswordRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import com.shopmanagement.service.EmailService;
import com.shopmanagement.service.EmailOtpService;
import com.shopmanagement.service.AuthService;
import com.shopmanagement.service.TokenBlacklistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenBlacklistService tokenBlacklistService;
    private final PasswordEncoder passwordEncoder;
    
    @Autowired
    private EmailService emailService;
    
    @Autowired
    private EmailOtpService emailOtpService;

    @Autowired
    private com.shopmanagement.service.MobileOtpService mobileOtpService;

    @Autowired
    private UserService userService;

    @Autowired
    private com.shopmanagement.repository.UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse authResponse = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success(authResponse, "Registration successful"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> authenticate(@Valid @RequestBody AuthRequest request) {
        AuthResponse authResponse = authService.authenticate(request);
        return ResponseEntity.ok(ApiResponse.success(authResponse, "Login successful"));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        // Extract and blacklist token
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            tokenBlacklistService.blacklistToken(token);
            return ResponseEntity.ok(ApiResponse.success(null, "Logged out successfully and token invalidated"));
        } else {
            return ResponseEntity.ok(ApiResponse.success(null, "Logged out successfully"));
        }
    }
    
    @GetMapping("/validate")
    public ResponseEntity<ApiResponse<Map<String, Object>>> validateToken(Authentication authentication) {
        if (authentication != null && authentication.isAuthenticated()) {
            Map<String, Object> data = new HashMap<>();
            data.put("valid", true);
            data.put("username", authentication.getName());
            data.put("authorities", authentication.getAuthorities());
            return ResponseEntity.ok(ApiResponse.success(data, "Token is valid"));
        } else {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.UNAUTHORIZED, ResponseConstants.UNAUTHORIZED_MESSAGE));
        }
    }
    
    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication) {
        
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.UNAUTHORIZED, "User not authenticated"));
        }
        
        try {
            authService.changePassword(request, authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(null, "Password changed successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.VALIDATION_ERROR, e.getMessage()));
        }
    }
    
    @GetMapping("/password-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPasswordStatus(Authentication authentication) {
        if (authentication != null && authentication.isAuthenticated()) {
            Map<String, Object> data = authService.getPasswordStatus(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(data, "Password status retrieved successfully"));
        } else {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.UNAUTHORIZED, "User not authenticated"));
        }
    }
    
    @PostMapping("/generate-password-hash")
    public ResponseEntity<ApiResponse<Map<String, String>>> generatePasswordHash(@RequestBody Map<String, String> request) {
        try {
            String rawPassword = request.get("password");
            if (rawPassword == null || rawPassword.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.REQUIRED_FIELD_MISSING, "Password is required"));
            }
            
            // Validate password strength
            if (rawPassword.length() < 8) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.VALIDATION_ERROR, "Password must be at least 8 characters long"));
            }
            
            String hashedPassword = passwordEncoder.encode(rawPassword);
            
            Map<String, String> data = new HashMap<>();
            data.put("rawPassword", rawPassword);
            data.put("hashedPassword", hashedPassword);
            data.put("sqlCommand", "UPDATE users SET password = '" + hashedPassword + "' WHERE username = 'your_username';");
            
            return ResponseEntity.ok(ApiResponse.success(data, "Password hash generated successfully. Use this hash in your database."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.GENERAL_ERROR, "Error generating password hash: " + e.getMessage()));
        }
    }
    
    @PostMapping("/send-otp")
    public ResponseEntity<ApiResponse<String>> sendOtp(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String purpose = request.getOrDefault("purpose", "REGISTRATION");

            if (email == null || email.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.REQUIRED_FIELD_MISSING, "Email is required"));
            }

            // Find user by email to get mobile number
            User user = authService.findUserByEmail(email);
            if (user == null) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.USER_NOT_FOUND, "User not found with this email"));
            }

            if (user.getMobileNumber() == null || user.getMobileNumber().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.VALIDATION_ERROR, "No mobile number found for this user"));
            }

            // Send OTP via SMS using mobile OTP service
            com.shopmanagement.dto.mobile.MobileOtpRequest otpRequest =
                com.shopmanagement.dto.mobile.MobileOtpRequest.builder()
                    .mobileNumber(user.getMobileNumber())
                    .purpose(purpose)
                    .deviceType("WEB")
                    .deviceId("web-" + user.getId())
                    .build();

            mobileOtpService.generateAndSendOtp(otpRequest);

            return ResponseEntity.ok(ApiResponse.success("OTP sent successfully to mobile", "OTP sent successfully"));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.GENERAL_ERROR, e.getMessage()));
        }
    }
    
    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String mobileNumber = request.get("mobileNumber");
            String otp = request.get("otp");
            String purpose = request.getOrDefault("purpose", "REGISTRATION");

            // Accept either email or mobile number
            if ((email == null || email.trim().isEmpty()) && (mobileNumber == null || mobileNumber.trim().isEmpty())) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.REQUIRED_FIELD_MISSING, "Email or mobile number is required"));
            }

            if (otp == null || otp.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.REQUIRED_FIELD_MISSING, "OTP is required"));
            }

            boolean isOtpValid = false;
            User user = null;

            // Try mobile verification first (for new registration flow with SMS)
            if (mobileNumber != null && !mobileNumber.trim().isEmpty()) {
                com.shopmanagement.dto.mobile.MobileOtpVerificationRequest verificationRequest =
                    com.shopmanagement.dto.mobile.MobileOtpVerificationRequest.builder()
                        .mobileNumber(mobileNumber)
                        .otp(otp)
                        .purpose(purpose)
                        .deviceType("WEB")
                        .deviceId("web-otp-verification")
                        .build();
                Map<String, Object> verificationResult = mobileOtpService.verifyOtp(verificationRequest);
                isOtpValid = (Boolean) verificationResult.getOrDefault("success", false);
                if (isOtpValid) {
                    user = authService.findUserByMobileNumber(mobileNumber);
                }
            }
            // Fallback to email verification if mobile not provided or failed
            else if (email != null && !email.trim().isEmpty()) {
                // Try to find user by email first to get mobile number
                user = authService.findUserByEmail(email);
                if (user != null && user.getMobileNumber() != null && !user.getMobileNumber().isEmpty()) {
                    // Try mobile OTP verification for email-based requests
                    com.shopmanagement.dto.mobile.MobileOtpVerificationRequest verificationRequest =
                        com.shopmanagement.dto.mobile.MobileOtpVerificationRequest.builder()
                            .mobileNumber(user.getMobileNumber())
                            .otp(otp)
                            .purpose(purpose)
                            .deviceType("WEB")
                            .deviceId("web-" + user.getId())
                            .build();
                    Map<String, Object> verificationResult = mobileOtpService.verifyOtp(verificationRequest);
                    isOtpValid = (Boolean) verificationResult.getOrDefault("success", false);
                }
                if (!isOtpValid) {
                    // Fallback to email OTP verification
                    isOtpValid = emailOtpService.verifyOtp(email, otp, purpose);
                    if (isOtpValid && user == null) {
                        user = authService.findUserByEmail(email);
                    }
                }
            }

            if (isOtpValid && user != null) {
                // Mark mobile as verified
                if (user.getMobileNumber() != null && !user.getMobileNumber().isEmpty()) {
                    user.setMobileVerified(true);
                    userRepository.save(user);
                }

                var jwtToken = authService.generateTokenForUser(user);

                AuthResponse authResponse = AuthResponse.builder()
                    .accessToken(jwtToken)
                    .tokenType("Bearer")
                    .userId(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .role(user.getRole().name())
                    .build();

                return ResponseEntity.ok(ApiResponse.success(authResponse, "OTP verified successfully"));
            } else if (user == null) {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.USER_NOT_FOUND, "User not found"));
            } else {
                return ResponseEntity.badRequest().body(
                    ApiResponse.error(ResponseConstants.VALIDATION_ERROR, "Invalid or expired OTP"));
            }

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                ApiResponse.error(ResponseConstants.GENERAL_ERROR, "OTP verification failed: " + e.getMessage()));
        }
    }
}