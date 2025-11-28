package com.shopmanagement.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductCategoryResponse {

    private Long id;
    private String name;
    private String nameTamil;
    private String description;
    private String slug;
    
    private Long parentId;
    private String parentName;
    private String fullPath; // e.g., "Electronics > Mobile > Smartphones"
    
    private Boolean isActive;
    private Integer sortOrder;
    private String iconUrl;
    
    private String createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Hierarchy info
    private List<ProductCategoryResponse> subcategories;
    private Boolean hasSubcategories;
    private Boolean isRootCategory;
    
    // Statistics
    private Long productCount;
    private Long subcategoryCount;
}