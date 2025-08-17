package com.shopmanagement.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerLocationDto {
    private String partnerId;
    private String partnerName;
    private Double lat;
    private Double lng;
    private Double heading;
    private Double speed;
    private Double accuracy;
    private LocalDateTime timestamp;
    private String orderId;
    private String status; // ONLINE, BUSY, OFFLINE
    private String vehicleType;
    private String vehicleNumber;
    private Double batteryLevel;
    private Boolean isMoving;
    private Double distanceTraveled;
    private Long sessionId;
}