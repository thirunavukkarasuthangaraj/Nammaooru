package com.shopmanagement.userservice.dto.mobile;

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
    private String purpose;

    private String deviceId;
    private String appVersion;
    private String deviceType;
    private String ipAddress;
    private String sessionId;
}
