package com.shopmanagement.delivery.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "delivery_tracking")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryTracking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id", nullable = false)
    private OrderAssignment orderAssignment;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal longitude;

    @Column(precision = 8, scale = 2)
    private BigDecimal accuracy;

    @Column(precision = 8, scale = 2)
    private BigDecimal altitude;

    @Column(precision = 8, scale = 2)
    private BigDecimal speed;

    @Column(precision = 5, scale = 2)
    private BigDecimal heading;

    @Column(name = "tracked_at")
    @Builder.Default
    private LocalDateTime trackedAt = LocalDateTime.now();

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "is_moving")
    @Builder.Default
    private Boolean isMoving = false;

    @Column(name = "estimated_arrival_time")
    private LocalDateTime estimatedArrivalTime;

    @Column(name = "distance_to_destination", precision = 8, scale = 2)
    private BigDecimal distanceToDestination;

    @Column(name = "distance_traveled", precision = 8, scale = 2)
    private BigDecimal distanceTraveled;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public boolean isRecent() {
        return trackedAt != null && trackedAt.isAfter(LocalDateTime.now().minusMinutes(5));
    }

    public boolean hasLowBattery() {
        return batteryLevel != null && batteryLevel < 20;
    }

    public BigDecimal getDistanceTraveled() {
        return distanceTraveled != null ? distanceTraveled : BigDecimal.ZERO;
    }
}