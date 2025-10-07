package com.shopmanagement.dto.order;

import com.shopmanagement.entity.Order;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderRequest {
    
    // @NotNull removed to allow userId or auth context - OrderService handles customer lookup
    private Long customerId;
    
    private Long userId;
    
    @NotNull(message = "Shop ID is required")
    private Long shopId;
    
    @NotEmpty(message = "Order items are required")
    private List<OrderItemRequest> orderItems;
    
    @NotNull(message = "Payment method is required")
    private Order.PaymentMethod paymentMethod;

    private String deliveryType; // SELF_PICKUP or HOME_DELIVERY

    @Size(max = 500, message = "Notes cannot exceed 500 characters")
    private String notes;

    // Delivery Information (optional for SELF_PICKUP orders)
    @Size(max = 200, message = "Delivery address cannot exceed 200 characters")
    private String deliveryAddress;
    
    @Size(max = 100, message = "Delivery city cannot exceed 100 characters")
    private String deliveryCity;

    @Size(max = 100, message = "Delivery state cannot exceed 100 characters")
    private String deliveryState;

    @Pattern(regexp = "^[0-9]{6}$", message = "Postal code must be 6 digits")
    private String deliveryPostalCode;

    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Invalid phone number")
    private String deliveryPhone;

    @Size(max = 100, message = "Contact name cannot exceed 100 characters")
    private String deliveryContactName;
    
    private LocalDateTime estimatedDeliveryTime;
    
    private BigDecimal discountAmount;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OrderItemRequest {
        @NotNull(message = "Shop product ID is required")
        private Long shopProductId;
        
        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least 1")
        private Integer quantity;
        
        @Size(max = 500, message = "Special instructions cannot exceed 500 characters")
        private String specialInstructions;
    }
}