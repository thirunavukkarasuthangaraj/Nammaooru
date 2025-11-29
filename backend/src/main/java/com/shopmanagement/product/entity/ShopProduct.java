package com.shopmanagement.product.entity;

import com.shopmanagement.shop.entity.Shop;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "shop_products", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"shop_id", "master_product_id"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class ShopProduct {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "master_product_id", nullable = false)
    private MasterProduct masterProduct;

    // Pricing
    @NotNull
    @DecimalMin(value = "0.0")
    @Column(name = "price", precision = 10, scale = 2, nullable = false)
    private BigDecimal price;

    @DecimalMin(value = "0.0")
    @Column(name = "original_price", precision = 10, scale = 2)
    private BigDecimal originalPrice; // For discounts

    @DecimalMin(value = "0.0")
    @Column(name = "cost_price", precision = 10, scale = 2)
    private BigDecimal costPrice;

    // Inventory
    @Builder.Default
    @Min(0)
    @Column(name = "stock_quantity")
    private Integer stockQuantity = 0;

    @Min(0)
    @Column(name = "min_stock_level")
    private Integer minStockLevel;

    @Min(0)
    @Column(name = "max_stock_level")
    private Integer maxStockLevel;

    @Builder.Default
    @Column(name = "track_inventory")
    private Boolean trackInventory = true;

    // Status and Availability
    @Builder.Default
    @Enumerated(EnumType.STRING)
    private ShopProductStatus status = ShopProductStatus.ACTIVE;

    @Builder.Default
    @Column(name = "is_available")
    private Boolean isAvailable = true;

    @Builder.Default
    @Column(name = "is_featured")
    private Boolean isFeatured = false;

    // Shop-specific customizations
    @Column(name = "custom_name")
    private String customName; // Shop can override product name

    @Column(name = "custom_description", length = 1000)
    private String customDescription;

    @Column(name = "custom_attributes", length = 2000)
    private String customAttributes; // JSON for shop-specific attributes

    // Shop-specific unit override (if null, uses master product's unit)
    @Column(name = "base_weight")
    private Double baseWeight;

    @Size(max = 50)
    @Column(name = "base_unit", length = 50)
    private String baseUnit;

    // SEO and Display
    @Column(name = "display_order")
    private Integer displayOrder;

    @Size(max = 1000)
    private String tags; // Comma-separated tags

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "updated_by")
    private String updatedBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relationships - Using Set to avoid MultipleBagFetchException
    @OneToMany(mappedBy = "shopProduct", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<ShopProductImage> shopImages = new HashSet<>();

    public enum ShopProductStatus {
        ACTIVE, INACTIVE, OUT_OF_STOCK, DISCONTINUED
    }

    // Business logic methods
    public String getDisplayName() {
        return customName != null ? customName : masterProduct.getName();
    }

    public String getDisplayDescription() {
        return customDescription != null ? customDescription : masterProduct.getDescription();
    }

    public boolean isInStock() {
        if (trackInventory == null || !trackInventory) return true;
        return stockQuantity != null && stockQuantity > 0;
    }

    public boolean isLowStock() {
        if (trackInventory == null || !trackInventory || minStockLevel == null) return false;
        return stockQuantity != null && stockQuantity <= minStockLevel;
    }

    public BigDecimal getDiscountAmount() {
        if (originalPrice == null || price == null) return BigDecimal.ZERO;
        return originalPrice.subtract(price);
    }

    public BigDecimal getDiscountPercentage() {
        if (originalPrice == null || price == null || originalPrice.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        return getDiscountAmount()
                .multiply(BigDecimal.valueOf(100))
                .divide(originalPrice, 2, BigDecimal.ROUND_HALF_UP);
    }

    public String getPrimaryShopImageUrl() {
        // First try shop-specific images
        String shopImageUrl = shopImages.stream()
                .filter(ShopProductImage::getIsPrimary)
                .map(ShopProductImage::getImageUrl)
                .findFirst()
                .orElse(null);
        
        if (shopImageUrl != null) return shopImageUrl;
        
        // Fallback to master product image
        return masterProduct.getPrimaryImageUrl();
    }
}