package com.shopmanagement.dto.mobile;

import com.shopmanagement.entity.Customer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MobileCustomerResponse {
    
    private Long customerId;
    private String firstName;
    private String lastName;
    private String fullName;
    private String email;
    private String mobileNumber;
    private Customer.Gender gender;
    private Customer.CustomerStatus status;
    
    // Account status
    private Boolean isActive;
    private Boolean isVerified;
    private Boolean emailVerified;
    private Boolean mobileVerified;
    
    // Location info
    private String city;
    private String state;
    private String pincode;
    
    // Preferences
    private Boolean emailNotifications;
    private Boolean smsNotifications;
    private Boolean pushNotifications;
    private Boolean promotionalEmails;
    private Boolean promotionalSms;
    
    // Customer metrics
    private Integer totalOrders;
    private Double totalSpent;
    private String referralCode;
    private Integer referralCount;
    
    // Timestamps
    private LocalDateTime memberSince;
    private LocalDateTime lastLoginDate;
    
    // JWT token for authentication
    private String accessToken;
    private String refreshToken;
    private Long tokenExpiresIn; // in seconds
    
    // App-specific data
    private String welcomeMessage;
    private Boolean isFirstLogin;
    private String profileCompletionStatus; // BASIC, PARTIAL, COMPLETE
    private Integer profileCompletionPercentage;
    
    // Feature flags for mobile app
    private Boolean canPlaceOrder;
    private Boolean canViewOrders;
    private Boolean canTrackDelivery;
    private Boolean canAddAddress;
    private Boolean canInviteFriends;
}