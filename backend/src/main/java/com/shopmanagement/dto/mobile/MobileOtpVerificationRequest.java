package com.shopmanagement.dto.mobile;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MobileOtpVerificationRequest {
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Please provide a valid 10-digit mobile number")
    private String mobileNumber;
    
    @NotBlank(message = "OTP is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "OTP must be 6 digits")
    private String otp;
    
    @NotBlank(message = "Purpose is required")
    private String purpose;
    
    // Device information for security
    @NotBlank(message = "Device ID is required")
    private String deviceId;
    
    private String appVersion;
    private String deviceType;
    
    // Session tracking
    private String sessionId;
}