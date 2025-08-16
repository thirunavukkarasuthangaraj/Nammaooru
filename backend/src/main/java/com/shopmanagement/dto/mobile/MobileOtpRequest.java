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
public class MobileOtpRequest {
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Please provide a valid 10-digit mobile number")
    private String mobileNumber;
    
    @NotBlank(message = "Purpose is required")
    @Pattern(regexp = "^(REGISTRATION|LOGIN|FORGOT_PASSWORD|CHANGE_MOBILE)$", 
             message = "Invalid OTP purpose")
    private String purpose;
    
    // Optional for tracking and security
    private String deviceId;
    private String appVersion;
    private String deviceType;
    
    // For rate limiting and fraud prevention
    private String ipAddress;
    private String sessionId;
}