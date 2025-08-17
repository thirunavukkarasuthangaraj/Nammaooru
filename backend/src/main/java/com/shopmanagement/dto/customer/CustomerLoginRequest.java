package com.shopmanagement.dto.customer;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomerLoginRequest {

    @NotBlank(message = "Email or mobile number is required")
    private String emailOrMobile;

    @NotBlank(message = "Password is required")
    private String password;

    // Optional device information for tracking
    private String deviceId;
    private String deviceType;
    private String appVersion;
    private String ipAddress;
}