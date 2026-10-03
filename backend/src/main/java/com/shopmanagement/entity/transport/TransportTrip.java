package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transport_trips")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TransportTrip {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transporter_id", nullable = false)
    private Long transporterId;

    @Column(name = "vehicle_id", nullable = false)
    private Long vehicleId;

    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(name = "route_id")
    private Long routeId;

    /** AB = From->To, BA = To->From */
    @Column(nullable = false, length = 2)
    @Builder.Default
    private String direction = "AB";

    @Column(name = "schedule_id")
    private Long scheduleId;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    @Column(name = "distance_km", precision = 10, scale = 2)
    private BigDecimal distanceKm;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Status status = Status.RUNNING;

    public enum Status { RUNNING, ENDED }
}
