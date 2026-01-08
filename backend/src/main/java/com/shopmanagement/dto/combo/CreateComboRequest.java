package com.shopmanagement.dto.combo;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateComboRequest {

    @NotBlank(message = "Combo name is required")
    @Size(max = 255, message = "Name cannot exceed 255 characters")
    private String name;

    @Size(max = 255, message = "Tamil name cannot exceed 255 characters")
    private String nameTamil;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    private String description;

    @Size(max = 2000, message = "Tamil description cannot exceed 2000 characters")
    private String descriptionTamil;

    @Size(max = 500, message = "Banner image URL cannot exceed 500 characters")
    private String bannerImageUrl;

    @NotNull(message = "Combo price is required")
    @DecimalMin(value = "0.01", message = "Combo price must be greater than 0")
    private BigDecimal comboPrice;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    @Min(value = 1, message = "Max quantity per order must be at least 1")
    private Integer maxQuantityPerOrder = 5;

    private Integer totalQuantityAvailable;

    private Boolean isActive = true;

    private Integer displayOrder = 0;

    @NotEmpty(message = "At least one item is required in the combo")
    private List<ComboItemRequest> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ComboItemRequest {
        @NotNull(message = "Shop product ID is required")
        private Long shopProductId;

        @Min(value = 1, message = "Quantity must be at least 1")
        private Integer quantity = 1;

        private Integer displayOrder = 0;
    }
}
