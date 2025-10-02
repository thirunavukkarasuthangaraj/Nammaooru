package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "emergencies")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Emergency {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "emergency_id", unique = true, nullable = false)
    private String emergencyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private User partner;

    @Column(name = "emergency_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private EmergencyType emergencyType;

    @Column(name = "status", nullable = false)
    @Enumerated(EnumType.STRING)
    private EmergencyStatus status;

    @Column(name = "severity", nullable = false)
    @Enumerated(EnumType.STRING)
    private EmergencySeverity severity;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "location_address")
    private String locationAddress;

    @Column(name = "was_on_delivery")
    private Boolean wasOnDelivery;

    @Column(name = "order_id")
    private String orderId;

    @Column(name = "requires_police")
    private Boolean requiresPolice;

    @Column(name = "requires_ambulance")
    private Boolean requiresAmbulance;

    @Column(name = "estimated_response_time")
    private String estimatedResponseTime;

    @Column(name = "actual_response_time")
    private String actualResponseTime;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @Column(name = "resolved_by")
    private String resolvedBy;

    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Emergency Type Enum
    public enum EmergencyType {
        ACCIDENT,
        ROBBERY,
        MEDICAL,
        VEHICLE_BREAKDOWN,
        OTHER
    }

    // Emergency Status Enum
    public enum EmergencyStatus {
        ACTIVE,
        IN_PROGRESS,
        RESOLVED,
        CANCELLED
    }

    // Emergency Severity Enum
    public enum EmergencySeverity {
        CRITICAL,
        HIGH,
        MEDIUM,
        LOW
    }
}