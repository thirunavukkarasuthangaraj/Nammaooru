package com.shopmanagement.dto.mobile;

import com.shopmanagement.entity.Customer;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MobileCustomerRegistrationRequest {
    
    @NotBlank(message = "First name is required")
    @Size(min = 2, max = 50, message = "First name must be between 2 and 50 characters")
    private String firstName;
    
    @Size(max = 50, message = "Last name must be less than 50 characters")
    private String lastName; // Optional for mobile registration
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Please provide a valid 10-digit mobile number")
    private String mobileNumber;
    
    @Email(message = "Please provide a valid email address")
    private String email; // Optional - can be collected later
    
    private Customer.Gender gender;
    
    // Optional fields for better user experience
    private String city;
    private String state;
    
    // App-specific fields
    @NotBlank(message = "Device ID is required")
    private String deviceId;
    
    @NotBlank(message = "App version is required")
    private String appVersion;
    
    private String deviceType; // ANDROID, IOS
    private String fcmToken; // For push notifications
    
    // Preferences
    @Builder.Default
    private Boolean emailNotifications = true;
    
    @Builder.Default
    private Boolean smsNotifications = true;
    
    @Builder.Default
    private Boolean pushNotifications = true;
    
    // Marketing preferences
    @Builder.Default
    private Boolean promotionalEmails = false;
    
    @Builder.Default
    private Boolean promotionalSms = false;
    
    // Location for delivery (optional during registration)
    private Double latitude;
    private Double longitude;
    private String pincode;
    
    // Referral code if any
    private String referralCode;
    
    // Terms and privacy acceptance
    @NotNull(message = "Terms and conditions must be accepted")
    @AssertTrue(message = "Terms and conditions must be accepted")
    private Boolean acceptTerms;
    
    @NotNull(message = "Privacy policy must be accepted")
    @AssertTrue(message = "Privacy policy must be accepted")
    private Boolean acceptPrivacy;
    
    // Optional newsletter subscription
    private Boolean subscribeNewsletter;
    
    // Compatibility method
    public Boolean getAcceptMarketing() {
        return promotionalEmails || promotionalSms || subscribeNewsletter;
    }
}