package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transport_position_history")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TransportPositionHistory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "vehicle_id", nullable = false)
    private Long vehicleId;

    @Column(name = "trip_id", nullable = false)
    private Long tripId;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "speed_kmh", precision = 6, scale = 1)
    private BigDecimal speedKmh;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;
}
