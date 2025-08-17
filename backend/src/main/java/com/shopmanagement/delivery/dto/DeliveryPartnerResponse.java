package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.DeliveryPartner;
import lombok.Data;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class DeliveryPartnerResponse {

    private Long id;
    private String partnerId;
    private String fullName;
    private String phoneNumber;
    private String alternatePhone;
    private String email;
    private LocalDate dateOfBirth;
    private DeliveryPartner.Gender gender;
    
    // Address Information
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    
    // Vehicle Information
    private DeliveryPartner.VehicleType vehicleType;
    private String vehicleNumber;
    private String vehicleModel;
    private String vehicleColor;
    private String licenseNumber;
    private LocalDate licenseExpiryDate;
    
    // Bank Information
    private String bankAccountNumber;
    private String bankIfscCode;
    private String bankName;
    private String accountHolderName;
    
    // Service Information
    private BigDecimal maxDeliveryRadius;
    private DeliveryPartner.PartnerStatus status;
    private DeliveryPartner.VerificationStatus verificationStatus;
    private Boolean isOnline;
    private Boolean isAvailable;
    
    // Performance Metrics
    private BigDecimal rating;
    private Integer totalDeliveries;
    private Integer successfulDeliveries;
    private BigDecimal totalEarnings;
    private BigDecimal successRate;
    
    // Current Location
    private BigDecimal currentLatitude;
    private BigDecimal currentLongitude;
    private LocalDateTime lastLocationUpdate;
    
    // Emergency Contact
    private String emergencyContactName;
    private String emergencyContactPhone;
    private String profileImageUrl;
    
    // Audit Information
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Document Verification Status
    private Long totalDocuments;
    private Long verifiedDocuments;
    private Boolean allDocumentsVerified;
}