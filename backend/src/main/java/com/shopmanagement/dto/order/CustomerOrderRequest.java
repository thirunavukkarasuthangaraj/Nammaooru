package com.shopmanagement.dto.order;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class CustomerOrderRequest {
    private Long customerId;
    private Long shopId;
    private String deliveryType; // SELF_PICKUP or HOME_DELIVERY
    private List<OrderItemRequest> items;
    private DeliveryAddressRequest deliveryAddress;
    private String paymentMethod;
    private BigDecimal subtotal;
    private BigDecimal deliveryFee;
    private BigDecimal discount;
    private BigDecimal total;
    private String notes;
    private CustomerInfoRequest customerInfo;
    private String customerToken; // Firebase token for notifications

    // Promo code fields
    private String promoCode; // The promo code applied (if any)
    private Long promotionId; // The promotion ID (if promo code was applied)
    private String deviceUuid; // Device UUID for tracking promo usage
    
    @Data
    public static class OrderItemRequest {
        private Long productId;
        private String productName;
        private BigDecimal price;
        private Integer quantity;
        private String unit;
    }
    
    @Data
    public static class DeliveryAddressRequest {
        private String streetAddress;
        private String landmark;
        private String city;
        private String state;
        private String pincode;
    }
    
    @Data
    public static class CustomerInfoRequest {
        private Long customerId;
        private String firstName;
        private String lastName;
        private String phone;
        private String email;
    }
}