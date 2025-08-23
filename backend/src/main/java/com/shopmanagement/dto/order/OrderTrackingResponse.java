package com.shopmanagement.dto.order;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class OrderTrackingResponse {
    private Long orderId;
    private String orderNumber;
    private String status;
    private BigDecimal total;
    private List<OrderStatusUpdate> statusHistory;
    private DeliveryPartnerInfo deliveryPartner;
    private String estimatedDeliveryTime;
    private LocationInfo currentLocation;
    
    @Data
    public static class OrderStatusUpdate {
        private String status;
        private LocalDateTime timestamp;
        private String message;
        private LocationInfo location;
    }
    
    @Data
    public static class DeliveryPartnerInfo {
        private Long id;
        private String name;
        private String phone;
        private String vehicleType;
        private String vehicleNumber;
        private Double rating;
    }
    
    @Data
    public static class LocationInfo {
        private Double lat;
        private Double lng;
    }
}