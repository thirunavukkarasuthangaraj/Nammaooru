package com.shopmanagement.dto.mobile;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MobileLoginRequest {
    
    @NotBlank(message = "Mobile number is required")
    private String mobileNumber;
    
    @NotBlank(message = "OTP is required")
    private String otp;
    
    // Device information
    private String deviceId;
    private String deviceType; // ANDROID, IOS
    private String appVersion;
    private String fcmToken; // For push notifications
    
    // Session information
    private String ipAddress;
    private String userAgent;
    
    // Remember login preference
    @Builder.Default
    private Boolean rememberDevice = false;
}