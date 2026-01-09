package com.shopmanagement.shop.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ShopUpdateRequest {

    @Size(max = 255, message = "Shop name cannot exceed 255 characters")
    private String name;

    @Size(max = 255, message = "Shop name (Tamil) cannot exceed 255 characters")
    private String nameTamil;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    private String description;

    @Size(max = 255, message = "Owner name cannot exceed 255 characters")
    private String ownerName;

    @Email(message = "Owner email should be valid")
    @Size(max = 255, message = "Owner email cannot exceed 255 characters")
    private String ownerEmail;

    @Size(max = 20, message = "Owner phone cannot exceed 20 characters")
    private String ownerPhone;

    @Size(max = 255, message = "Business name cannot exceed 255 characters")
    private String businessName;

    @Pattern(regexp = "GROCERY|PHARMACY|RESTAURANT|GENERAL", message = "Business type must be GROCERY, PHARMACY, RESTAURANT, or GENERAL")
    private String businessType;

    @Size(max = 500, message = "Address cannot exceed 500 characters")
    private String addressLine1;

    @Size(max = 100, message = "City cannot exceed 100 characters")
    private String city;

    @Size(max = 100, message = "State cannot exceed 100 characters")
    private String state;

    @Size(max = 20, message = "Postal code cannot exceed 20 characters")
    private String postalCode;

    @Size(max = 100, message = "Country cannot exceed 100 characters")
    private String country;

    @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    private BigDecimal latitude;

    @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    private BigDecimal longitude;

    @DecimalMin(value = "0.0", message = "Minimum order amount cannot be negative")
    private BigDecimal minOrderAmount;

    @DecimalMin(value = "0.0", message = "Delivery radius cannot be negative")
    private BigDecimal deliveryRadius;


    @DecimalMin(value = "0.0", message = "Free delivery threshold cannot be negative")
    private BigDecimal freeDeliveryAbove;

    @DecimalMin(value = "0.0", message = "Commission rate cannot be negative")
    @DecimalMax(value = "100.0", message = "Commission rate cannot exceed 100")
    private BigDecimal commissionRate;

    @Size(max = 15, message = "GST number cannot exceed 15 characters")
    private String gstNumber;

    @Size(max = 10, message = "PAN number cannot exceed 10 characters")
    private String panNumber;

    @Pattern(regexp = "PENDING|APPROVED|REJECTED|SUSPENDED", message = "Status must be PENDING, APPROVED, REJECTED, or SUSPENDED")
    private String status;

    private Boolean isActive;
    
    private Boolean isVerified;
    
    private Boolean isFeatured;
}