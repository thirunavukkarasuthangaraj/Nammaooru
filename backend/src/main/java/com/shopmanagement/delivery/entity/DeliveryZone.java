package com.shopmanagement.delivery.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Entity
@Table(name = "delivery_zones")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryZone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "zone_name", nullable = false, length = 100)
    private String zoneName;

    @Column(name = "zone_code", unique = true, nullable = false, length = 20)
    private String zoneCode;

    @Column(columnDefinition = "jsonb", nullable = false)
    private String boundaries;

    @Column(name = "delivery_fee", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal deliveryFee = BigDecimal.ZERO;

    @Column(name = "min_order_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal minOrderAmount = BigDecimal.ZERO;

    @Column(name = "max_delivery_time")
    @Builder.Default
    private Integer maxDeliveryTime = 60;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "service_start_time")
    @Builder.Default
    private LocalTime serviceStartTime = LocalTime.of(6, 0);

    @Column(name = "service_end_time")
    @Builder.Default
    private LocalTime serviceEndTime = LocalTime.of(23, 0);

    @OneToMany(mappedBy = "deliveryZone", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<PartnerZoneAssignment> partnerAssignments;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public boolean isOperationalNow() {
        LocalTime now = LocalTime.now();
        return isActive && now.isAfter(serviceStartTime) && now.isBefore(serviceEndTime);
    }

    public boolean canAcceptOrders() {
        return isActive && isOperationalNow();
    }
}