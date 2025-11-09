package com.shopmanagement.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkImportRequest {

    // Master Product Fields
    private String name;
    private String nameTamil;
    private String description;
    private String sku;
    private String barcode;
    private Long categoryId;
    private String brand;
    private String baseUnit;
    private BigDecimal baseWeight;
    private String specifications;
    private String status; // ACTIVE, INACTIVE, DISCONTINUED
    private Boolean isFeatured;
    private Boolean isGlobal;

    // Shop Product Fields (for shop owners)
    private BigDecimal originalPrice;
    private BigDecimal sellingPrice;
    private BigDecimal discountPercentage;
    private BigDecimal costPrice;
    private Integer stockQuantity;
    private Integer minStockLevel;
    private Integer maxStockLevel;
    private Boolean trackInventory;
    private String shopProductStatus; // ACTIVE, OUT_OF_STOCK, INACTIVE
    private Boolean isAvailable;
    private String customName;
    private String customDescription;
    private String tags;

    // Image handling
    private String imagePath; // Path to image file or URL
    private String imageFolder; // Subfolder to organize images (e.g., "electronics", "groceries")

    // For tracking
    private Integer rowNumber;
}
