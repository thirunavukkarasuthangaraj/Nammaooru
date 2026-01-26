package com.shopmanagement.product.dto;

import com.shopmanagement.product.entity.ShopProduct;
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
public class ShopProductRequest {

    // Note: masterProductId is required for CREATE but optional for UPDATE
    // Validation is handled in the service layer based on operation type
    private Long masterProductId;

    // Note: price is required for CREATE but optional for UPDATE (partial updates)
    @DecimalMin(value = "0.0", message = "Price must be positive")
    private BigDecimal price;

    @DecimalMin(value = "0.0", message = "Original price must be positive")
    private BigDecimal originalPrice;

    @DecimalMin(value = "0.0", message = "Cost price must be positive")
    private BigDecimal costPrice;

    @Min(value = 0, message = "Stock quantity cannot be negative")
    @Builder.Default
    private Integer stockQuantity = 0;

    @Min(value = 0, message = "Minimum stock level cannot be negative")
    private Integer minStockLevel;

    @Min(value = 0, message = "Maximum stock level cannot be negative")
    private Integer maxStockLevel;

    @Builder.Default
    private Boolean trackInventory = true;

    @Builder.Default
    private ShopProduct.ShopProductStatus status = ShopProduct.ShopProductStatus.ACTIVE;

    @Builder.Default
    private Boolean isAvailable = true;

    @Builder.Default
    private Boolean isFeatured = false;

    @Size(max = 255, message = "Custom name must be less than 255 characters")
    private String customName;

    @Size(max = 1000, message = "Custom description must be less than 1000 characters")
    private String customDescription;

    @Size(max = 2000, message = "Custom attributes must be less than 2000 characters")
    private String customAttributes;

    private Integer displayOrder;

    @Size(max = 1000, message = "Tags must be less than 1000 characters")
    private String tags;

    private List<String> shopImageUrls;

    // Master product fields (for updating master product properties)
    private Double baseWeight;

    @Size(max = 50, message = "Base unit must be less than 50 characters")
    private String baseUnit;

    // Master product SKU/Barcode (for shop owner to update product identification)
    @Size(max = 100, message = "SKU must be less than 100 characters")
    private String sku;

    @Size(max = 100, message = "Barcode must be less than 100 characters")
    private String barcode;

    // Shop-level multiple barcodes (different packaging, supplier codes, etc.)
    @Size(max = 100, message = "Barcode1 must be less than 100 characters")
    private String barcode1;

    @Size(max = 100, message = "Barcode2 must be less than 100 characters")
    private String barcode2;

    @Size(max = 100, message = "Barcode3 must be less than 100 characters")
    private String barcode3;

    // Master product voice search tags (comma-separated tags for voice search)
    @Size(max = 2000, message = "Voice search tags must be less than 2000 characters")
    private String voiceSearchTags;

    // Tamil name for the product
    @Size(max = 255, message = "Tamil name must be less than 255 characters")
    private String nameTamil;

    // Category for auto-created master products (offline/custom product creation)
    private Long categoryId;

    @Size(max = 100, message = "Category name must be less than 100 characters")
    private String categoryName;
}
