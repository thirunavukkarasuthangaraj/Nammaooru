package com.shopmanagement.dto.order;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PosOrderItemRequest {

    @NotNull(message = "Shop product ID is required")
    private Long shopProductId;

    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;

    // Optional: Override price (for discounts)
    private BigDecimal unitPrice;

    // Optional: Special instructions
    private String notes;
}
