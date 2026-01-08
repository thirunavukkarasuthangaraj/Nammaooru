package com.shopmanagement.dto.combo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComboResponse {

    private Long id;
    private Long shopId;
    private String shopName;
    private String name;
    private String nameTamil;
    private String description;
    private String descriptionTamil;
    private String bannerImageUrl;
    private BigDecimal comboPrice;
    private BigDecimal originalPrice;
    private BigDecimal savings;
    private BigDecimal discountPercentage;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean isActive;
    private Integer maxQuantityPerOrder;
    private Integer totalQuantityAvailable;
    private Integer totalSold;
    private Integer displayOrder;
    private Integer itemCount;
    private List<ComboItemResponse> items;
    private String status; // ACTIVE, INACTIVE, SCHEDULED, EXPIRED, OUT_OF_STOCK
    private Boolean isAvailable;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ComboItemResponse {
        private Long id;
        private Long shopProductId;
        private String productName;
        private String productNameTamil;
        private String productDescription;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
        private String unit;
        private String imageUrl;
        private Integer stockQuantity;
        private Boolean inStock;
        private Integer displayOrder;
    }
}
