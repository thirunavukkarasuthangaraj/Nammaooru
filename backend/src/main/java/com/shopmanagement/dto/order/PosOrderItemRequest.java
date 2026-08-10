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

    // Null or negative for custom items typed at the counter (no catalog product)
    private Long shopProductId;

    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;

    // Optional: Override price (for discounts). Required for custom items.
    private BigDecimal unitPrice;

    // Item name for custom items (ignored for catalog products)
    private String productName;

    // Optional: Special instructions
    private String notes;
}
