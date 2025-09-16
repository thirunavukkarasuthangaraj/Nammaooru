package com.shopmanagement.shop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ShopResponse {

    private Long id;
    private String name;
    private String description;
    private String shopId;
    private String slug;
    
    private String ownerName;
    private String ownerEmail;
    private String ownerPhone;
    private String businessName;
    private String businessType;
    
    private String addressLine1;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    private BigDecimal latitude;
    private BigDecimal longitude;
    
    private BigDecimal minOrderAmount;
    private BigDecimal deliveryRadius;
    private BigDecimal freeDeliveryAbove;
    private BigDecimal commissionRate;
    
    private String gstNumber;
    private String panNumber;
    
    private String status;
    private Boolean isActive;
    private Boolean isVerified;
    private Boolean isFeatured;
    
    private BigDecimal rating;
    private Integer totalOrders;
    private BigDecimal totalRevenue;
    private Integer productCount;
    
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    private List<ShopImageResponse> images;
    private List<ShopDocumentResponse> documents;
}