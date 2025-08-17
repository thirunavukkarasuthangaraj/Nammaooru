package com.shopmanagement.dto.customer;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomerResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String fullName;
    private String email;
    private String mobileNumber;
    private String alternateMobileNumber;
    private String gender;
    private LocalDate dateOfBirth;
    private String status;

    // Address Information
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    private String formattedAddress;
    private Double latitude;
    private Double longitude;

    // Preferences
    private Boolean emailNotifications;
    private Boolean smsNotifications;
    private Boolean promotionalEmails;
    private String preferredLanguage;

    // Customer Metrics
    private Integer totalOrders;
    private Double totalSpent;
    private LocalDateTime lastOrderDate;
    private LocalDateTime lastLoginDate;

    // Account Information
    private Boolean isVerified;
    private Boolean isActive;
    private Boolean emailVerified;
    private Boolean mobileVerified;
    private LocalDateTime emailVerifiedAt;
    private LocalDateTime mobileVerifiedAt;
    private String referralCode;
    private String referredBy;

    // Audit Fields
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}