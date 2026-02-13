package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "bus_timings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BusTiming {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "bus_number", nullable = false)
    private String busNumber;

    @Column(name = "bus_name")
    private String busName;

    @Column(name = "route_from", nullable = false)
    private String routeFrom;

    @Column(name = "route_to", nullable = false)
    private String routeTo;

    @Column(name = "via_stops")
    private String viaStops;

    @Column(name = "departure_time", nullable = false)
    private String departureTime;

    @Column(name = "arrival_time")
    private String arrivalTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "bus_type", nullable = false)
    @Builder.Default
    private BusType busType = BusType.GOVERNMENT;

    @Column(name = "operating_days", nullable = false)
    @Builder.Default
    private String operatingDays = "DAILY";

    @Column(name = "fare", precision = 10, scale = 2)
    private BigDecimal fare;

    @Column(name = "location_area", nullable = false)
    private String locationArea;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum BusType {
        GOVERNMENT, PRIVATE
    }
}
