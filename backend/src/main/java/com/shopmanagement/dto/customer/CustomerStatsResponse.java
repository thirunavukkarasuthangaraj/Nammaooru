package com.shopmanagement.dto.customer;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerStatsResponse {
    
    private Long totalCustomers;
    private Long activeCustomers;
    private Long inactiveCustomers;
    private Long verifiedCustomers;
    private Long unverifiedCustomers;
    private Long blockedCustomers;
    private Long newCustomersThisMonth;
    private Long newCustomersToday;
    
    // Financial Stats
    private Double totalSpending;
    private Double averageOrderValue;
    private Double averageOrdersPerCustomer;
    
    // Demographic Stats
    private Long maleCustomers;
    private Long femaleCustomers;
    private Long otherGenderCustomers;
    
    // Location Stats
    private String topCity;
    private String topState;
    private Long customersInTopCity;
    private Long customersInTopState;
    
    // Engagement Stats
    private Long customersWithEmailNotifications;
    private Long customersWithSmsNotifications;
    private Long customersWithPromotionalEmails;
    private Long customersWithMultipleAddresses;
    
    // Verification Stats
    private Long emailVerifiedCustomers;
    private Long mobileVerifiedCustomers;
    private Long fullyVerifiedCustomers;
    
    // Referral Stats
    private Long customersWithReferrals;
    private Long totalReferrals;
    private Double averageReferralsPerCustomer;
}