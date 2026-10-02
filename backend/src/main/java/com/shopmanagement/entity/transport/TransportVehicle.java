package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "transport_vehicles")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class TransportVehicle {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transporter_id", nullable = false)
    private Long transporterId;

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type", nullable = false, length = 20)
    @Builder.Default
    private VehicleType vehicleType = VehicleType.BUS;

    @Column(name = "reg_no", nullable = false, length = 30)
    private String regNo;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(name = "route_id")
    private Long routeId;

    @Column(name = "driver_id")
    private Long driverId;

    /** Only BUS vehicles can be public. Public buses show on "Where is Bus" for everyone. */
    @Column(name = "is_public", nullable = false)
    @Builder.Default
    private Boolean isPublic = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Status status = Status.ACTIVE;

    @CreatedDate @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum VehicleType { BUS, LORRY, VAN, AUTO, CAR, BIKE, TRACTOR, OTHER }
    public enum Status { ACTIVE, INACTIVE, DELETED }
}
