package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.OrderAssignment;
import com.shopmanagement.dto.order.OrderResponse;
import lombok.Data;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class OrderAssignmentResponse {

    private Long id;
    private Long orderId;
    private String orderNumber;
    private OrderResponse order; // Full order details if needed
    
    private Long partnerId;
    private String partnerName;
    private String partnerPhone;
    private DeliveryPartnerResponse partner; // Full partner details if needed
    
    private LocalDateTime assignedAt;
    private Long assignedBy;
    private String assignedByName;
    private OrderAssignment.AssignmentType assignmentType;
    
    // Status Information
    private OrderAssignment.AssignmentStatus status;
    private LocalDateTime acceptedAt;
    private LocalDateTime pickupTime;
    private LocalDateTime deliveryTime;
    
    // Location Information
    private BigDecimal pickupLatitude;
    private BigDecimal pickupLongitude;
    private BigDecimal deliveryLatitude;
    private BigDecimal deliveryLongitude;
    
    // Financial Information
    private BigDecimal deliveryFee;
    private BigDecimal partnerCommission;
    
    // Additional Information
    private String rejectionReason;
    private String deliveryNotes;
    private Integer customerRating;
    private String customerFeedback;
    
    // Tracking Information
    private BigDecimal currentLatitude;
    private BigDecimal currentLongitude;
    private LocalDateTime lastLocationUpdate;
    private BigDecimal distanceToDestination;
    private LocalDateTime estimatedArrivalTime;
    
    // Timing Information
    private Long totalTimeMinutes;
    private Long deliveryTimeMinutes;
    private Boolean isDelayed;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}