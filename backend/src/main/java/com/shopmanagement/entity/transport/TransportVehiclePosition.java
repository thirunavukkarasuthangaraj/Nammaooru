package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Latest known position, one row per vehicle (upserted on every GPS send). */
@Entity
@Table(name = "transport_vehicle_positions")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TransportVehiclePosition {
    @Id
    @Column(name = "vehicle_id")
    private Long vehicleId;

    @Column(name = "trip_id")
    private Long tripId;

    @Column(name = "driver_id")
    private Long driverId;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "speed_kmh", precision = 6, scale = 1)
    private BigDecimal speedKmh;

    @Column(precision = 5, scale = 1)
    private BigDecimal heading;

    @Column(name = "accuracy_m", precision = 7, scale = 1)
    private BigDecimal accuracyM;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;
}
