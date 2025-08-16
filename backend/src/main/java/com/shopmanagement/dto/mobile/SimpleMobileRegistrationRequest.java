package com.shopmanagement.dto.mobile;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SimpleMobileRegistrationRequest {
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Please provide a valid 10-digit mobile number")
    private String mobileNumber;
    
    // Device information for security
    private String deviceId;
    private String deviceType; // ANDROID, IOS
    private String appVersion;
    
    // Session information
    private String ipAddress;
    private String userAgent;
}