package com.shopmanagement.delivery.entity;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "order_assignments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private DeliveryPartner deliveryPartner;

    @Column(name = "assigned_at")
    @Builder.Default
    private LocalDateTime assignedAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_by")
    private User assignedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "assignment_type", length = 20)
    @Builder.Default
    private AssignmentType assignmentType = AssignmentType.AUTO;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    @Builder.Default
    private AssignmentStatus status = AssignmentStatus.ASSIGNED;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "pickup_time")
    private LocalDateTime pickupTime;

    @Column(name = "delivery_time")
    private LocalDateTime deliveryTime;

    @Column(name = "pickup_latitude", precision = 10, scale = 6)
    private BigDecimal pickupLatitude;

    @Column(name = "pickup_longitude", precision = 10, scale = 6)
    private BigDecimal pickupLongitude;

    @Column(name = "delivery_latitude", precision = 10, scale = 6)
    private BigDecimal deliveryLatitude;

    @Column(name = "delivery_longitude", precision = 10, scale = 6)
    private BigDecimal deliveryLongitude;

    @Column(name = "delivery_fee", precision = 10, scale = 2, nullable = false)
    private BigDecimal deliveryFee;

    @Column(name = "partner_commission", precision = 10, scale = 2)
    private BigDecimal partnerCommission;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "delivery_notes", columnDefinition = "TEXT")
    private String deliveryNotes;

    @Column(name = "customer_rating")
    private Integer customerRating;

    @Column(name = "customer_feedback", columnDefinition = "TEXT")
    private String customerFeedback;

    @OneToMany(mappedBy = "orderAssignment", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DeliveryTracking> trackingPoints;

    @OneToOne(mappedBy = "orderAssignment", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private PartnerEarning earning;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public boolean canBeAccepted() {
        return status == AssignmentStatus.ASSIGNED;
    }

    public boolean canBeRejected() {
        return status == AssignmentStatus.ASSIGNED;
    }

    public boolean canBePickedUp() {
        return status == AssignmentStatus.ACCEPTED;
    }

    public boolean canBeDelivered() {
        return status == AssignmentStatus.IN_TRANSIT;
    }

    public boolean isCompleted() {
        return status == AssignmentStatus.DELIVERED;
    }

    public boolean isFailed() {
        return status == AssignmentStatus.FAILED || 
               status == AssignmentStatus.CANCELLED || 
               status == AssignmentStatus.RETURNED;
    }

    public enum AssignmentType {
        AUTO, MANUAL
    }

    public enum AssignmentStatus {
        ASSIGNED, ACCEPTED, REJECTED, PICKED_UP, IN_TRANSIT,
        DELIVERED, FAILED, CANCELLED, RETURNED
    }
}