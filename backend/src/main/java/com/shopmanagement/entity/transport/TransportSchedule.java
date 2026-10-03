package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/** One scheduled departure of a vehicle: direction AB (From->To) or BA (To->From), HH:mm times. */
@Entity
@Table(name = "transport_schedules")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class TransportSchedule {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transporter_id", nullable = false)
    private Long transporterId;

    @Column(name = "vehicle_id", nullable = false)
    private Long vehicleId;

    @Column(name = "route_id")
    private Long routeId;

    @Column(nullable = false, length = 2)
    @Builder.Default
    private String direction = "AB";

    @Column(name = "depart_time", nullable = false, length = 5)
    private String departTime;

    @Column(name = "arrive_time", nullable = false, length = 5)
    private String arriveTime;

    @Column(nullable = false, length = 40)
    @Builder.Default
    private String days = "DAILY";

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
