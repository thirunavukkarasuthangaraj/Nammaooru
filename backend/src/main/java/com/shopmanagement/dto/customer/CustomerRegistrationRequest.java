package com.shopmanagement.dto.customer;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomerRegistrationRequest {

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

    @Pattern(regexp = "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY", message = "Gender must be MALE, FEMALE, OTHER, or PREFER_NOT_TO_SAY")
    private String gender;

    @Past(message = "Date of birth must be in the past")
    private LocalDate dateOfBirth;

    // Address Information
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    private Double latitude;
    private Double longitude;

    // Preferences
    @Builder.Default
    private Boolean emailNotifications = true;

    @Builder.Default
    private Boolean smsNotifications = true;

    @Builder.Default
    private Boolean promotionalEmails = false;

    private String preferredLanguage;

    // Referral
    private String referredBy;

    // Optional password for account creation
    @Size(min = 4, max = 100, message = "Password must be between 4 and 100 characters")
    private String password;
}