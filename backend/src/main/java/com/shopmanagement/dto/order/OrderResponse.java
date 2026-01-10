package com.shopmanagement.dto.order;

import com.shopmanagement.entity.Order;
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
public class OrderResponse {
    
    private Long id;
    private String orderNumber;
    private Order.OrderStatus status;
    private Order.PaymentStatus paymentStatus;
    private Order.PaymentMethod paymentMethod;
    
    // Customer Info
    private Long customerId;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    
    // Shop Info
    private Long shopId;
    private String shopName;
    private String shopAddress;
    
    // Financial Details
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal deliveryFee;
    private BigDecimal discountAmount;
    private BigDecimal totalAmount;
    private String couponCode;
    
    private String notes;
    private String cancellationReason;
    
    // Delivery Information
    private String deliveryType;
    private String deliveryAddress;
    private String deliveryCity;
    private String deliveryState;
    private String deliveryPostalCode;
    private String deliveryPhone;
    private String deliveryContactName;
    private String fullDeliveryAddress;

    private LocalDateTime estimatedDeliveryTime;
    private LocalDateTime actualDeliveryTime;
    
    private List<OrderItemResponse> orderItems;
    
    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Helper fields
    private String statusLabel;
    private String paymentStatusLabel;
    private String paymentMethodLabel;
    private boolean canBeCancelled;
    private boolean isDelivered;
    private boolean isPaid;
    private Boolean assignedToDeliveryPartner;
    private String orderAge;
    private Integer itemCount;
    private String driverSearchStartedAt;
    private Boolean driverSearchCompleted;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OrderItemResponse {
        private Long id;
        private Long shopProductId;
        private String productName;
        private String productNameTamil;
        private String productDescription;
        private String productSku;
        private String productImageUrl;
        private String unit;
        private Long shopId;
        private String shopName;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
        private String specialInstructions;
    }
}