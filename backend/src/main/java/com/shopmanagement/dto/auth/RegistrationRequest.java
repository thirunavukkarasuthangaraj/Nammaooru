package com.shopmanagement.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegistrationRequest {
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid mobile number format")
    private String mobileNumber;
    
    @NotBlank(message = "OTP is required")
    @Size(min = 6, max = 6, message = "OTP must be 6 digits")
    private String otp;
    
    @NotBlank(message = "First name is required")
    @Size(min = 2, max = 50, message = "First name must be between 2 and 50 characters")
    private String firstName;
    
    @Size(max = 50, message = "Last name cannot exceed 50 characters")
    private String lastName;
    
    @Email(message = "Please provide a valid email address")
    private String email;
    
    @NotBlank(message = "User type is required")
    @Pattern(regexp = "CUSTOMER|SHOP_OWNER|DELIVERY_PARTNER", message = "Invalid user type")
    private String userType;
    
    // For shop owners
    private String shopName;
    private String shopAddress;
    private String shopCategory;
    
    // Device info
    private String deviceToken;
    private String deviceType;
    
    // Marketing preferences
    private Boolean acceptMarketing;
    private Boolean acceptTerms;
}