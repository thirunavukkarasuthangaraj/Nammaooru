package com.shopmanagement.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductImageResponse {

    private Long id;
    private String imageUrl;
    private String altText;
    private Boolean isPrimary;
    private Integer sortOrder;
    private String createdBy;
    private LocalDateTime createdAt;
    
    // Additional metadata
    private String imageType; // "MASTER" or "SHOP"
    private Long productId; // master_product_id or shop_product_id
}