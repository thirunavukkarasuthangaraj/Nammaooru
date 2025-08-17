package com.shopmanagement.dto.customer;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomerOrderRequest {

    @NotNull(message = "Shop ID is required")
    private Long shopId;

    @NotNull(message = "Order items are required")
    @Size(min = 1, message = "At least one item is required")
    @Valid
    private List<OrderItemRequest> items;

    @NotNull(message = "Payment method is required")
    @Pattern(regexp = "CASH_ON_DELIVERY|ONLINE|UPI|CARD", message = "Payment method must be CASH_ON_DELIVERY, ONLINE, UPI, or CARD")
    private String paymentMethod;

    // Delivery Information
    @NotBlank(message = "Delivery address is required")
    @Size(max = 500, message = "Delivery address cannot exceed 500 characters")
    private String deliveryAddress;

    @NotBlank(message = "Delivery contact name is required")
    @Size(max = 100, message = "Delivery contact name cannot exceed 100 characters")
    private String deliveryContactName;

    @NotBlank(message = "Delivery phone is required")
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid delivery phone number")
    private String deliveryPhone;

    @NotBlank(message = "Delivery city is required")
    @Size(max = 100, message = "Delivery city cannot exceed 100 characters")
    private String deliveryCity;

    @NotBlank(message = "Delivery state is required")
    @Size(max = 100, message = "Delivery state cannot exceed 100 characters")
    private String deliveryState;

    @NotBlank(message = "Delivery postal code is required")
    @Size(max = 20, message = "Delivery postal code cannot exceed 20 characters")
    private String deliveryPostalCode;

    @Size(max = 1000, message = "Special instructions cannot exceed 1000 characters")
    private String specialInstructions;

    @Size(max = 500, message = "Notes cannot exceed 500 characters")
    private String notes;

    private LocalDateTime estimatedDeliveryTime;

    private BigDecimal discountAmount;

    private String couponCode;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class OrderItemRequest {

        @NotNull(message = "Shop product ID is required")
        private Long shopProductId;

        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least 1")
        @Max(value = 100, message = "Quantity cannot exceed 100")
        private Integer quantity;

        @NotNull(message = "Unit price is required")
        @DecimalMin(value = "0.0", message = "Unit price must be positive")
        private BigDecimal unitPrice;

        @Size(max = 500, message = "Special instructions cannot exceed 500 characters")
        private String specialInstructions;
    }
}