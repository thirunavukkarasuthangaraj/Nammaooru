package com.shopmanagement.controller;

import com.shopmanagement.dto.mobile.*;
import com.shopmanagement.service.CustomerService;
import com.shopmanagement.service.MobileOtpService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.Map;

@RestController
@RequestMapping("/api/mobile")
@RequiredArgsConstructor
@Slf4j
public class MobileCustomerController {
    
    private final MobileOtpService mobileOtpService;
    private final CustomerService customerService;
    
    @PostMapping("/auth/request-otp")
    public ResponseEntity<Map<String, Object>> requestOtpForAuth(
            @Valid @RequestBody SimpleMobileRegistrationRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("OTP request for mobile authentication: {}", request.getMobileNumber());
            
            // Set IP address from request
            request.setIpAddress(getClientIpAddress(httpRequest));
            
            // Create OTP request for LOGIN purpose
            MobileOtpRequest otpRequest = MobileOtpRequest.builder()
                    .mobileNumber(request.getMobileNumber())
                    .purpose("LOGIN")
                    .deviceId(request.getDeviceId())
                    .deviceType(request.getDeviceType())
                    .appVersion(request.getAppVersion())
                    .ipAddress(request.getIpAddress())
                    .build();
            
            Map<String, Object> response = mobileOtpService.generateAndSendOtp(otpRequest);
            
            // Check if customer exists for the response
            boolean customerExists = customerService.customerExistsByMobile(request.getMobileNumber());
            response.put("customerExists", customerExists);
            response.put("action", customerExists ? "LOGIN" : "REGISTRATION");
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error requesting OTP for mobile: {}", request.getMobileNumber(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to send OTP. Please try again.",
                        "errorCode", "INTERNAL_ERROR"
                    ));
        }
    }
    
    @PostMapping("/otp/generate")
    public ResponseEntity<Map<String, Object>> generateOtp(
            @Valid @RequestBody MobileOtpRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("OTP generation request received for mobile: {}", request.getMobileNumber());
            
            // Set IP address from request
            request.setIpAddress(getClientIpAddress(httpRequest));
            
            Map<String, Object> response = mobileOtpService.generateAndSendOtp(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error generating OTP for mobile: {}", request.getMobileNumber(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to generate OTP. Please try again.",
                        "errorCode", "INTERNAL_ERROR"
                    ));
        }
    }
    
    @PostMapping("/otp/verify")
    public ResponseEntity<Map<String, Object>> verifyOtp(
            @Valid @RequestBody MobileOtpVerificationRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("OTP verification request received for mobile: {}", request.getMobileNumber());
            
            // IP address logging can be handled in service layer if needed
            
            Map<String, Object> response = mobileOtpService.verifyOtp(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error verifying OTP for mobile: {}", request.getMobileNumber(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to verify OTP. Please try again.",
                        "errorCode", "INTERNAL_ERROR"
                    ));
        }
    }
    
    @PostMapping("/otp/resend")
    public ResponseEntity<Map<String, Object>> resendOtp(
            @RequestParam String mobileNumber,
            @RequestParam String purpose,
            @RequestParam(required = false) String deviceId,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("OTP resend request received for mobile: {}", mobileNumber);
            
            Map<String, Object> response = mobileOtpService.resendOtp(mobileNumber, purpose, deviceId);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error resending OTP for mobile: {}", mobileNumber, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to resend OTP. Please try again.",
                        "errorCode", "INTERNAL_ERROR"
                    ));
        }
    }
    
    @PostMapping("/customer/register")
    public ResponseEntity<Map<String, Object>> registerCustomer(
            @Valid @RequestBody MobileCustomerRegistrationRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("Customer registration request received for mobile: {}", request.getMobileNumber());
            
            // First verify that OTP was verified for this mobile number and registration purpose
            Map<String, Object> otpValidation = validateOtpForRegistration(
                request.getMobileNumber(), 
                request.getDeviceId()
            );
            
            if (!(Boolean) otpValidation.get("valid")) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of(
                            "success", false,
                            "message", otpValidation.get("message"),
                            "errorCode", "OTP_NOT_VERIFIED"
                        ));
            }
            
            // IP address logging can be handled in service layer if needed
            
            // Register the customer
            Map<String, Object> response = customerService.registerMobileCustomer(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error registering customer for mobile: {}", request.getMobileNumber(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Registration failed. Please try again.",
                        "errorCode", "REGISTRATION_ERROR"
                    ));
        }
    }
    
    @PostMapping("/auth/login")
    public ResponseEntity<Map<String, Object>> mobileLogin(
            @Valid @RequestBody MobileLoginRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("Mobile login request received for: {}", request.getMobileNumber());
            
            // Set IP address
            request.setIpAddress(getClientIpAddress(httpRequest));
            
            // Authenticate customer
            Map<String, Object> response = customerService.authenticateMobileCustomer(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error during mobile login for: {}", request.getMobileNumber(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Login failed. Please try again.",
                        "errorCode", "LOGIN_ERROR"
                    ));
        }
    }
    
    @PostMapping("/auth/refresh-token")
    public ResponseEntity<Map<String, Object>> refreshToken(
            @RequestBody Map<String, String> request) {
        
        try {
            String refreshToken = request.get("refreshToken");
            if (refreshToken == null || refreshToken.isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of(
                            "success", false,
                            "message", "Refresh token is required",
                            "errorCode", "MISSING_REFRESH_TOKEN"
                        ));
            }
            
            Map<String, Object> response = customerService.refreshMobileAuthToken(refreshToken);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error refreshing token", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to refresh token",
                        "errorCode", "TOKEN_REFRESH_ERROR"
                    ));
        }
    }
    
    @GetMapping("/customer/profile")
    public ResponseEntity<Map<String, Object>> getCustomerProfile(
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            String token = extractTokenFromHeader(authHeader);
            if (token == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of(
                            "success", false,
                            "message", "Invalid authorization header",
                            "errorCode", "INVALID_TOKEN"
                        ));
            }
            
            Map<String, Object> response = customerService.getMobileCustomerProfile(token);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error getting customer profile", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to get profile",
                        "errorCode", "PROFILE_ERROR"
                    ));
        }
    }
    
    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getMobileAppConfig() {
        try {
            Map<String, Object> config = Map.of(
                "appName", "NammaOoru",
                "version", "1.0.0",
                "otpValidityMinutes", 10,
                "minPasswordLength", 4,
                "maxOtpAttemptsPerDay", 5,
                "supportedCountries", new String[]{"IN"},
                "features", Map.of(
                    "referralProgram", true,
                    "socialLogin", false,
                    "biometricLogin", true,
                    "pushNotifications", true,
                    "locationServices", true
                ),
                "endpoints", Map.of(
                    "termsOfService", "/terms",
                    "privacyPolicy", "/privacy",
                    "support", "/support",
                    "helpCenter", "/help"
                )
            );
            
            return ResponseEntity.ok(Map.of("success", true, "config", config));
            
        } catch (Exception e) {
            log.error("Error getting mobile app config", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to get app config",
                        "errorCode", "CONFIG_ERROR"
                    ));
        }
    }
    
    // Helper methods
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }
    
    private Map<String, Object> validateOtpForRegistration(String mobileNumber, String deviceId) {
        // Check if there's a recent verified OTP for REGISTRATION purpose
        boolean isValid = mobileOtpService.hasVerifiedOtp(mobileNumber, "REGISTRATION", deviceId);

        if (isValid) {
            return Map.of(
                "valid", true,
                "message", "OTP verification valid"
            );
        } else {
            return Map.of(
                "valid", false,
                "message", "Please verify your mobile number with OTP before registering"
            );
        }
    }
    
    private String extractTokenFromHeader(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        return null;
    }
}