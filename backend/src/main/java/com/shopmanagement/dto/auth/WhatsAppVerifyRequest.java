package com.shopmanagement.dto.auth;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Data
public class WhatsAppVerifyRequest {

    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Please enter a valid 10-digit Indian mobile number")
    private String mobileNumber;

    @NotBlank(message = "OTP is required")
    @Size(min = 4, max = 6, message = "OTP must be between 4-6 digits")
    @Pattern(regexp = "^\\d+$", message = "OTP must contain only digits")
    private String otp;

    private String deviceToken;

    @Pattern(regexp = "^(android|ios|web)$", message = "Device type must be android, ios, or web")
    private String deviceType = "android";

    public WhatsAppVerifyRequest() {}

    public WhatsAppVerifyRequest(String mobileNumber, String otp, String deviceToken, String deviceType) {
        this.mobileNumber = mobileNumber;
        this.otp = otp;
        this.deviceToken = deviceToken;
        this.deviceType = deviceType != null ? deviceType : "android";
    }
}