package com.shopmanagement.delivery.dto;

import lombok.Data;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class DeliveryTrackingResponse {

    private Long id;
    private Long assignmentId;
    private String orderNumber;
    
    // Current Location
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private BigDecimal altitude;
    private BigDecimal speed;
    private BigDecimal heading;
    
    // Tracking Information
    private LocalDateTime trackedAt;
    private Integer batteryLevel;
    private Boolean isMoving;
    
    // Delivery Information
    private LocalDateTime estimatedArrivalTime;
    private BigDecimal distanceToDestination;
    
    // Partner Information
    private String partnerName;
    private String partnerPhone;
    private String vehicleType;
    private String vehicleNumber;
    
    // Order Information
    private String customerName;
    private String customerPhone;
    private String deliveryAddress;
    private String orderStatus;
    private String assignmentStatus;
    
    // Route Information
    private BigDecimal totalDistance;
    private Integer estimatedTimeMinutes;
    private Boolean isDelayed;
    
    // Historical Tracking Points
    private List<TrackingPoint> trackingHistory;
    
    @Data
    @Builder
    public static class TrackingPoint {
        private BigDecimal latitude;
        private BigDecimal longitude;
        private LocalDateTime trackedAt;
        private BigDecimal speed;
        private Boolean isMoving;
    }
}