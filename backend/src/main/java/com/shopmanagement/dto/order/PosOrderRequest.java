package com.shopmanagement.dto.order;

import com.shopmanagement.entity.Order;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
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
public class PosOrderRequest {

    @NotNull(message = "Shop ID is required")
    private Long shopId;

    @NotEmpty(message = "At least one item is required")
    @Valid
    private List<PosOrderItemRequest> items;

    @NotNull(message = "Payment method is required")
    private Order.PaymentMethod paymentMethod;

    // Optional customer info (for walk-in customers)
    private String customerName;
    private String customerPhone;

    // Optional notes
    private String notes;

    // For offline sync - unique ID generated on client
    private String offlineOrderId;

    // Optional: Apply discount
    private BigDecimal discountAmount;

    // Optional: Discount reason
    private String discountReason;
}
