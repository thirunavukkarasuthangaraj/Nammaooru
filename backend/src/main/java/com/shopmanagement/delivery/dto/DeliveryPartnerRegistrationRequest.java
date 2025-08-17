package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.DeliveryPartner;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class DeliveryPartnerRegistrationRequest {

    @NotBlank(message = "Full name is required")
    @Size(max = 255, message = "Full name must not exceed 255 characters")
    private String fullName;

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid phone number format")
    private String phoneNumber;

    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid alternate phone number format")
    private String alternatePhone;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotNull(message = "Date of birth is required")
    @Past(message = "Date of birth must be in the past")
    private LocalDate dateOfBirth;

    @NotNull(message = "Gender is required")
    private DeliveryPartner.Gender gender;

    @NotBlank(message = "Address line 1 is required")
    @Size(max = 500, message = "Address line 1 must not exceed 500 characters")
    private String addressLine1;

    @Size(max = 500, message = "Address line 2 must not exceed 500 characters")
    private String addressLine2;

    @NotBlank(message = "City is required")
    @Size(max = 100, message = "City must not exceed 100 characters")
    private String city;

    @NotBlank(message = "State is required")
    @Size(max = 100, message = "State must not exceed 100 characters")
    private String state;

    @NotBlank(message = "Postal code is required")
    @Pattern(regexp = "^[1-9][0-9]{5}$", message = "Invalid postal code format")
    private String postalCode;

    private String country = "India";

    @NotNull(message = "Vehicle type is required")
    private DeliveryPartner.VehicleType vehicleType;

    @NotBlank(message = "Vehicle number is required")
    @Pattern(regexp = "^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$", message = "Invalid vehicle number format")
    private String vehicleNumber;

    @Size(max = 100, message = "Vehicle model must not exceed 100 characters")
    private String vehicleModel;

    @Size(max = 50, message = "Vehicle color must not exceed 50 characters")
    private String vehicleColor;

    @NotBlank(message = "License number is required")
    @Size(max = 30, message = "License number must not exceed 30 characters")
    private String licenseNumber;

    @NotNull(message = "License expiry date is required")
    @Future(message = "License expiry date must be in the future")
    private LocalDate licenseExpiryDate;

    @Size(max = 20, message = "Bank account number must not exceed 20 characters")
    private String bankAccountNumber;

    @Pattern(regexp = "^[A-Z]{4}0[A-Z0-9]{6}$", message = "Invalid IFSC code format")
    private String bankIfscCode;

    @Size(max = 100, message = "Bank name must not exceed 100 characters")
    private String bankName;

    @Size(max = 255, message = "Account holder name must not exceed 255 characters")
    private String accountHolderName;

    @DecimalMin(value = "1.0", message = "Maximum delivery radius must be at least 1 km")
    @DecimalMax(value = "50.0", message = "Maximum delivery radius must not exceed 50 km")
    private BigDecimal maxDeliveryRadius = BigDecimal.valueOf(10);

    @Size(max = 255, message = "Emergency contact name must not exceed 255 characters")
    private String emergencyContactName;

    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid emergency contact phone format")
    private String emergencyContactPhone;

    // User account details
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;
}