package com.shopmanagement.product.dto;

import com.shopmanagement.product.entity.MasterProduct;
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
public class MasterProductResponse {

    private Long id;
    private String name;
    private String nameTamil;
    private String description;
    private String sku;
    private String barcode;
    
    private ProductCategoryResponse category;
    
    private String brand;
    private String baseUnit;
    private BigDecimal baseWeight;
    private String specifications;
    
    private MasterProduct.ProductStatus status;
    private Boolean isFeatured;
    private Boolean isGlobal;
    
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    private List<ProductImageResponse> images;
    private String primaryImageUrl;
    
    // Additional computed fields
    private Long shopCount; // Number of shops selling this product
    private BigDecimal minPrice; // Lowest price across all shops
    private BigDecimal maxPrice; // Highest price across all shops
}