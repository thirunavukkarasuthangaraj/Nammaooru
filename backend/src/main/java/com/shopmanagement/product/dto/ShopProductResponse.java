package com.shopmanagement.product.dto;

import com.shopmanagement.product.entity.ShopProduct;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductResponse {

    private Long id;
    private Long shopId;
    private String shopName;
    
    // Master product info
    private MasterProductResponse masterProduct;
    
    // Pricing
    private BigDecimal price;
    private BigDecimal originalPrice;
    private BigDecimal costPrice;
    
    // Inventory
    private Integer stockQuantity;
    private Integer minStockLevel;
    private Integer maxStockLevel;
    private Boolean trackInventory;
    
    // Status
    private ShopProduct.ShopProductStatus status;
    private Boolean isAvailable;
    private Boolean isFeatured;
    
    // Customizations
    private String customName;
    private String customNameTamil;
    private String customDescription;
    private String customAttributes;

    // Shop-specific unit override (if null, uses master product's unit)
    private Double baseWeight;
    private String baseUnit;

    // Display
    private String displayName; // Computed: custom name or master name
    private String displayNameTamil; // Computed: custom name Tamil or master name Tamil
    private String displayDescription; // Computed: custom description or master description
    private String nameTamil; // Top-level convenience field for mobile apps
    private Integer displayOrder;
    private String tags;
    
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Images
    private List<ProductImageResponse> shopImages;
    private String primaryImageUrl; // Computed: shop image or master image
    
    // Computed fields
    private Boolean inStock;
    private Boolean lowStock;
    private BigDecimal discountAmount;
    private BigDecimal discountPercentage;
    private BigDecimal profitMargin; // (price - costPrice) / costPrice * 100
}