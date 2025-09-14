package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "delivery_partner_locations", indexes = {
    @Index(name = "idx_partner_time", columnList = "partner_id, recorded_at DESC"),
    @Index(name = "idx_location_spatial", columnList = "latitude, longitude"),
    @Index(name = "idx_recorded_at", columnList = "recorded_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryPartnerLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "partner_id", nullable = false)
    private Long partnerId;

    @Column(precision = 10, scale = 8, nullable = false)
    private BigDecimal latitude;

    @Column(precision = 11, scale = 8, nullable = false)
    private BigDecimal longitude;

    @Column(precision = 5, scale = 2)
    private BigDecimal accuracy;

    @Column(precision = 5, scale = 2)
    private BigDecimal speed;

    @Column(precision = 5, scale = 2)
    private BigDecimal heading;

    @Column(precision = 8, scale = 2)
    private BigDecimal altitude;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;

    @Column(name = "is_moving")
    private Boolean isMoving;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "network_type", length = 20)
    private String networkType;

    @Column(name = "assignment_id")
    private Long assignmentId;

    @Column(name = "order_status", length = 50)
    private String orderStatus;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (recordedAt == null) {
            recordedAt = LocalDateTime.now();
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (isMoving == null) {
            isMoving = false;
        }
    }

    // Helper method to calculate if partner is moving based on speed
    public boolean isActuallyMoving() {
        return speed != null && speed.compareTo(BigDecimal.valueOf(1.0)) > 0;
    }
}