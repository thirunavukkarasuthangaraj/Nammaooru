package com.shopmanagement.dto.customer;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerAddressResponse {
    
    private Long id;
    private Long customerId;
    private String addressType;
    private String addressLabel;
    private String addressLine1;
    private String addressLine2;
    private String landmark;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    private String fullAddress;
    private Double latitude;
    private Double longitude;
    private Boolean isDefault;
    private Boolean isActive;
    
    // Contact Information
    private String contactPersonName;
    private String contactMobileNumber;
    
    // Delivery Instructions
    private String deliveryInstructions;
    
    // Timestamps
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Helper fields for UI
    private String displayLabel;
    private String shortAddress;
}