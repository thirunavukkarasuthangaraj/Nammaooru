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
public class DeliveryLocationResponse {

    private Long id;
    private String addressType;
    private String flatHouse;
    private String floor;
    private String street;
    private String area;
    private String village;
    private String addressLine1; // For mobile app compatibility
    private String addressLine2; // For mobile app compatibility
    private String landmark;
    private String city;
    private String state;
    private String pincode;
    private String fullAddress;
    private Double latitude;
    private Double longitude;
    private Boolean isDefault;
    private Boolean isActive;

    // Contact information
    private String contactPersonName;
    private String contactMobileNumber;

    // Timestamps
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Helper fields for UI
    private String displayLabel;
    private String shortAddress;
}