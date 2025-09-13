package com.shopmanagement.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OTPResponse {
    
    private boolean success;
    private String message;
    private String sessionId; // For tracking OTP session
    private Integer expiryInMinutes;
    private LocalDateTime expiryTime;
    private String channel; // "whatsapp" or "sms"
    private Integer attemptsLeft;
    private String testOTP; // Only for testing/development
    
    // For successful verification
    private String token; // JWT token after successful OTP verification
    private Long userId;
    private String userType; // "CUSTOMER", "SHOP_OWNER", etc.
    private boolean isNewUser;
}