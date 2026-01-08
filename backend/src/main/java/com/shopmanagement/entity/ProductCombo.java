package com.shopmanagement.entity;

import com.shopmanagement.shop.entity.Shop;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.EqualsAndHashCode;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "product_combos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class ProductCombo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Shop shop;

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

    @Size(max = 2000)
    @Column(name = "description_tamil", columnDefinition = "TEXT")
    private String descriptionTamil;

    @Size(max = 500)
    @Column(name = "banner_image_url")
    private String bannerImageUrl;

    @NotNull
    @DecimalMin(value = "0.01")
    @Column(name = "combo_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal comboPrice;

    @NotNull
    @DecimalMin(value = "0.01")
    @Column(name = "original_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal originalPrice;

    @Column(name = "discount_percentage", precision = 5, scale = 2)
    private BigDecimal discountPercentage;

    @NotNull
    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @NotNull
    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Builder.Default
    @Column(name = "is_active")
    private Boolean isActive = true;

    @Builder.Default
    @Column(name = "max_quantity_per_order")
    private Integer maxQuantityPerOrder = 5;

    @Column(name = "total_quantity_available")
    private Integer totalQuantityAvailable;

    @Builder.Default
    @Column(name = "total_sold")
    private Integer totalSold = 0;

    @Builder.Default
    @Column(name = "display_order")
    private Integer displayOrder = 0;

    @OneToMany(mappedBy = "combo", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private List<ComboItem> items = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @CreatedBy
    @Column(name = "created_by", updatable = false)
    private String createdBy;

    @LastModifiedBy
    @Column(name = "updated_by")
    private String updatedBy;

    // Helper methods
    public void addItem(ComboItem item) {
        items.add(item);
        item.setCombo(this);
    }

    public void removeItem(ComboItem item) {
        items.remove(item);
        item.setCombo(null);
    }

    public void clearItems() {
        items.forEach(item -> item.setCombo(null));
        items.clear();
    }

    public int getItemCount() {
        return items != null ? items.size() : 0;
    }

    public BigDecimal getSavings() {
        if (originalPrice != null && comboPrice != null) {
            return originalPrice.subtract(comboPrice);
        }
        return BigDecimal.ZERO;
    }

    public boolean isCurrentlyActive() {
        if (!Boolean.TRUE.equals(isActive)) return false;
        LocalDate today = LocalDate.now();
        return !today.isBefore(startDate) && !today.isAfter(endDate);
    }

    public boolean isExpired() {
        return LocalDate.now().isAfter(endDate);
    }

    public boolean isScheduled() {
        return LocalDate.now().isBefore(startDate);
    }

    @PrePersist
    @PreUpdate
    public void calculateDiscountPercentage() {
        if (originalPrice != null && comboPrice != null && originalPrice.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = originalPrice.subtract(comboPrice);
            this.discountPercentage = discount.multiply(new BigDecimal("100"))
                    .divide(originalPrice, 2, java.math.RoundingMode.HALF_UP);
        }
    }
}
