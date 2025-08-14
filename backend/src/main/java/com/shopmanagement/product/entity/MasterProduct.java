package com.shopmanagement.product.entity;

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
@Table(name = "master_products")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class MasterProduct {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotBlank
    @Size(max = 255)
    @Column(nullable = false)
    private String name;

    @Column(length = 2000)
    private String description;

    @NotBlank
    @Size(max = 100)
    @Column(unique = true, nullable = false)
    private String sku;

    @Size(max = 100)
    private String barcode;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private ProductCategory category;

    @Size(max = 100)
    private String brand;

    @Column(name = "base_unit")
    private String baseUnit; // kg, liter, piece, etc.

    @DecimalMin(value = "0.0")
    @Column(name = "base_weight", precision = 10, scale = 3)
    private BigDecimal baseWeight;

    @Column(length = 1000)
    private String specifications; // JSON string for flexible attributes

    @Builder.Default
    @Enumerated(EnumType.STRING)
    private ProductStatus status = ProductStatus.ACTIVE;

    @Builder.Default
    @Column(name = "is_featured")
    private Boolean isFeatured = false;

    @Builder.Default
    @Column(name = "is_global")
    private Boolean isGlobal = true; // Available to all shops

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
    @OneToMany(mappedBy = "masterProduct", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<MasterProductImage> images = new HashSet<>();

    @OneToMany(mappedBy = "masterProduct", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<ShopProduct> shopProducts = new HashSet<>();

    public enum ProductStatus {
        ACTIVE, INACTIVE, DISCONTINUED
    }

    // Helper methods
    public String getPrimaryImageUrl() {
        return images.stream()
                .filter(MasterProductImage::getIsPrimary)
                .map(MasterProductImage::getImageUrl)
                .findFirst()
                .orElse(null);
    }

    public List<String> getAllImageUrls() {
        return images.stream()
                .map(MasterProductImage::getImageUrl)
                .toList();
    }
}