package com.shopmanagement.product.dto;

import com.shopmanagement.product.entity.MasterProduct;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MasterProductRequest {

    @NotBlank(message = "Product name is required")
    @Size(max = 255, message = "Product name must be less than 255 characters")
    private String name;

    @Size(max = 255, message = "Tamil name must be less than 255 characters")
    private String nameTamil;

    @Size(max = 2000, message = "Description must be less than 2000 characters")
    private String description;

    @Size(max = 100, message = "SKU must be less than 100 characters")
    private String sku; // Optional - will be auto-generated if not provided

    @Size(max = 100, message = "Barcode must be less than 100 characters")
    private String barcode;

    @NotNull(message = "Category is required")
    private Long categoryId;

    @Size(max = 100, message = "Brand must be less than 100 characters")
    private String brand;

    private String baseUnit;

    @DecimalMin(value = "0.0", message = "Base weight must be positive")
    private BigDecimal baseWeight;

    @Size(max = 1000, message = "Specifications must be less than 1000 characters")
    private String specifications;

    @Size(max = 2000, message = "Tags must be less than 2000 characters")
    private String tags; // Comma-separated tags for searching/filtering and Gemini voice search

    @Builder.Default
    private MasterProduct.ProductStatus status = MasterProduct.ProductStatus.ACTIVE;

    @Builder.Default
    private Boolean isFeatured = false;

    @Builder.Default
    private Boolean isGlobal = true;

    private List<String> imageUrls;
}