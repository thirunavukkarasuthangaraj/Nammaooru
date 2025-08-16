package com.shopmanagement.dto.customer;

import com.shopmanagement.entity.Customer;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerRequest {
    
    @NotBlank(message = "First name is required")
    @Size(min = 2, max = 50, message = "First name must be between 2 and 50 characters")
    private String firstName;
    
    @NotBlank(message = "Last name is required")
    @Size(min = 2, max = 50, message = "Last name must be between 2 and 50 characters")
    private String lastName;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Please provide a valid email address")
    private String email;
    
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid mobile number")
    private String mobileNumber;
    
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid alternate mobile number")
    private String alternateMobileNumber;
    
    private Customer.Gender gender;
    
    @Past(message = "Date of birth must be in the past")
    private LocalDate dateOfBirth;
    
    @Size(max = 500, message = "Notes cannot exceed 500 characters")
    private String notes;
    
    // Address Information
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String state;
    
    @Pattern(regexp = "^[0-9]{6}$", message = "Please provide a valid 6-digit postal code")
    private String postalCode;
    
    private String country;
    private Double latitude;
    private Double longitude;
    
    // Preferences
    private Boolean emailNotifications;
    private Boolean smsNotifications;
    private Boolean promotionalEmails;
    private String preferredLanguage;
    
    // Account settings
    private Boolean isActive;
    private Customer.CustomerStatus status;
    
    // Referral
    private String referredBy;
}