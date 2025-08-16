package com.shopmanagement.dto.customer;

import com.shopmanagement.entity.Customer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerResponse {
    
    private Long id;
    private String firstName;
    private String lastName;
    private String fullName;
    private String email;
    private String mobileNumber;
    private String alternateMobileNumber;
    private Customer.Gender gender;
    private LocalDate dateOfBirth;
    private Customer.CustomerStatus status;
    private String notes;
    
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
    private Integer referralCount;
    
    // Timestamps
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Related Data
    private List<CustomerAddressResponse> addresses;
    
    // Helper fields for UI
    private String statusLabel;
    private String genderLabel;
    private String memberSince;
    private String lastActivity;
}