package com.shopmanagement.shop.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.EqualsAndHashCode;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "shops")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Shop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 255)
    @Column(nullable = false)
    private String name;

    @Size(max = 255)
    @Column(name = "name_tamil")
    private String nameTamil;

    @Size(max = 2000)
    @Column(columnDefinition = "TEXT")
    private String description;

    @NotBlank
    @Size(max = 50)
    @Column(name = "shop_id", unique = true, nullable = false)
    private String shopId;

    @NotBlank
    @Size(max = 255)
    @Column(unique = true, nullable = false)
    private String slug;

    // Owner Information
    @NotBlank
    @Size(max = 255)
    @Column(name = "owner_name", nullable = false)
    private String ownerName;

    @NotBlank
    @Email
    @Size(max = 255)
    @Column(name = "owner_email", nullable = false)
    private String ownerEmail;

    @NotBlank
    @Size(max = 20)
    @Column(name = "owner_phone", nullable = false)
    private String ownerPhone;

    @Size(max = 255)
    @Column(name = "business_name")
    private String businessName;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "business_type", nullable = false)
    private BusinessType businessType;

    // Address Information
    @NotBlank
    @Size(max = 500)
    @Column(name = "address_line1", nullable = false)
    private String addressLine1;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false)
    private String city;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false)
    private String state;

    @NotBlank
    @Size(max = 20)
    @Column(name = "postal_code", nullable = false)
    private String postalCode;

    @Size(max = 100)
    @Builder.Default
    @Column(nullable = false)
    private String country = "India";

    @DecimalMin(value = "-90.0")
    @DecimalMax(value = "90.0")
    @Column(precision = 10, scale = 6)
    private BigDecimal latitude;

    @DecimalMin(value = "-180.0")
    @DecimalMax(value = "180.0")
    @Column(precision = 10, scale = 6)
    private BigDecimal longitude;

    // Business Settings
    @DecimalMin(value = "0.0")
    @Builder.Default
    @Column(name = "min_order_amount", precision = 10, scale = 2)
    private BigDecimal minOrderAmount = BigDecimal.ZERO;

    @DecimalMin(value = "0.0")
    @Builder.Default
    @Column(name = "delivery_radius", precision = 8, scale = 2)
    private BigDecimal deliveryRadius = new BigDecimal("5.0");


    @DecimalMin(value = "0.0")
    @Column(name = "free_delivery_above", precision = 10, scale = 2)
    private BigDecimal freeDeliveryAbove;

    @DecimalMin(value = "0.0")
    @DecimalMax(value = "100.0")
    @Builder.Default
    @Column(name = "commission_rate", precision = 5, scale = 2)
    private BigDecimal commissionRate = new BigDecimal("15.0");

    // Legal Information
    @Size(max = 15)
    @Column(name = "gst_number")
    private String gstNumber;

    @Size(max = 10)
    @Column(name = "pan_number")
    private String panNumber;

    @Size(max = 20)
    @Column(name = "fssai_certificate_number")
    private String fssaiCertificateNumber;

    @Size(max = 30)
    @Column(name = "grocery_license_number")
    private String groceryLicenseNumber;

    // Payment Information
    @Size(max = 100)
    @Column(name = "upi_id")
    private String upiId;

    // Status and Flags
    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(nullable = false)
    private ShopStatus status = ShopStatus.PENDING;

    @Builder.Default
    @Column(name = "is_active")
    private Boolean isActive = true;

    @Builder.Default
    @Column(name = "is_verified")
    private Boolean isVerified = false;

    @Builder.Default
    @Column(name = "is_featured")
    private Boolean isFeatured = false;

    // Availability Management
    @Builder.Default
    @Column(name = "is_available")
    private Boolean isAvailable = true;
    
    @Column(name = "availability_updated_at")
    private LocalDateTime availabilityUpdatedAt;
    
    @Builder.Default
    @Column(name = "is_manual_override")
    private Boolean isManualOverride = false;
    
    @Size(max = 500)
    @Column(name = "availability_override_reason")
    private String availabilityOverrideReason;

    // Performance Metrics
    @DecimalMin(value = "0.0")
    @DecimalMax(value = "5.0")
    @Builder.Default
    @Column(precision = 3, scale = 2)
    private BigDecimal rating = BigDecimal.ZERO;

    @Min(0)
    @Builder.Default
    @Column(name = "total_orders")
    private Integer totalOrders = 0;

    @DecimalMin(value = "0.0")
    @Builder.Default
    @Column(name = "total_revenue", precision = 15, scale = 2)
    private BigDecimal totalRevenue = BigDecimal.ZERO;

    @Min(0)
    @Builder.Default
    @Column(name = "product_count")
    private Integer productCount = 0;

    // Audit Fields
    @Size(max = 255)
    @Column(name = "created_by")
    private String createdBy;

    @Size(max = 255)
    @Column(name = "updated_by")
    private String updatedBy;

    // Timestamps
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relationships - Using Set instead of List to avoid MultipleBagFetchException
    @OneToMany(mappedBy = "shop", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Set<ShopImage> images = new HashSet<>();

    @OneToMany(mappedBy = "shop", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Set<ShopDocument> documents = new HashSet<>();

    public enum BusinessType {
        GROCERY, PHARMACY, RESTAURANT, GENERAL, FORMER_PRODUCTS, FOOD, MEDICINE, PARCEL
    }

    public enum ShopStatus {
        PENDING, APPROVED, REJECTED, SUSPENDED
    }
}