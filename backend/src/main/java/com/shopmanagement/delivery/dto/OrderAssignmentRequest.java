package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.OrderAssignment;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class OrderAssignmentRequest {

    @NotNull(message = "Order ID is required")
    private Long orderId;

    private Long partnerId; // Optional for auto-assignment

    @NotNull(message = "Assignment type is required")
    private OrderAssignment.AssignmentType assignmentType;

    @NotNull(message = "Delivery fee is required")
    @DecimalMin(value = "0.0", message = "Delivery fee must be non-negative")
    private BigDecimal deliveryFee;

    @DecimalMin(value = "0.0", message = "Partner commission must be non-negative")
    private BigDecimal partnerCommission;

    // Pickup location (optional, can be derived from shop)
    @DecimalMin(value = "-90.0", message = "Invalid latitude")
    @DecimalMax(value = "90.0", message = "Invalid latitude")
    private BigDecimal pickupLatitude;

    @DecimalMin(value = "-180.0", message = "Invalid longitude")
    @DecimalMax(value = "180.0", message = "Invalid longitude")
    private BigDecimal pickupLongitude;

    // Delivery location (optional, can be derived from order)
    @DecimalMin(value = "-90.0", message = "Invalid latitude")
    @DecimalMax(value = "90.0", message = "Invalid latitude")
    private BigDecimal deliveryLatitude;

    @DecimalMin(value = "-180.0", message = "Invalid longitude")
    @DecimalMax(value = "180.0", message = "Invalid longitude")
    private BigDecimal deliveryLongitude;

    @Size(max = 500, message = "Notes must not exceed 500 characters")
    private String notes;
}