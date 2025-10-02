package com.shopmanagement.dto.auth;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Data
public class WhatsAppOTPRequest {

    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Please enter a valid 10-digit Indian mobile number")
    private String mobileNumber;

    @NotBlank(message = "Channel is required")
    @Pattern(regexp = "^(whatsapp|sms)$", message = "Channel must be either 'whatsapp' or 'sms'")
    private String channel = "whatsapp";

    private String name;

    @NotBlank(message = "Purpose is required")
    @Pattern(regexp = "^(login|register|forgot_password)$", message = "Purpose must be login, register, or forgot_password")
    private String purpose = "login";

    public WhatsAppOTPRequest() {}

    public WhatsAppOTPRequest(String mobileNumber, String channel, String name, String purpose) {
        this.mobileNumber = mobileNumber;
        this.channel = channel != null ? channel : "whatsapp";
        this.name = name;
        this.purpose = purpose != null ? purpose : "login";
    }
}