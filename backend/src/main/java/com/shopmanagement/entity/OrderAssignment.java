package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

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
    @JoinColumn(name = "delivery_partner_id", nullable = false)
    private User deliveryPartner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_by", nullable = false)
    private User assignedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private AssignmentStatus status = AssignmentStatus.ASSIGNED;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private AssignmentType assignmentType = AssignmentType.AUTO;

    // Assignment timing
    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime assignedAt = LocalDateTime.now();

    private LocalDateTime acceptedAt;
    private LocalDateTime rejectedAt;
    private LocalDateTime pickupTime;
    private LocalDateTime deliveryCompletedAt;

    // Financial information
    @Column(nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal deliveryFee = BigDecimal.ZERO;

    @Column(precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal partnerCommission = BigDecimal.ZERO;

    // Location information
    @Column
    private Double shopLatitude;

    @Column
    private Double shopLongitude;

    @Column
    private Double deliveryLatitude;

    @Column
    private Double deliveryLongitude;

    // Notes and feedback
    @Column(length = 500)
    private String rejectionReason;

    @Column(length = 500)
    private String deliveryNotes;

    @Column(length = 500)
    private String assignmentNotes;

    // Customer rating and feedback
    private Integer customerRating;

    @Column(length = 500)
    private String customerFeedback;

    // Settlement information
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settlement_id")
    private PaymentSettlement paymentSettlement;

    @Column(name = "is_settled")
    @Builder.Default
    private Boolean isSettled = false;

    @Column(name = "settled_at")
    private LocalDateTime settledAt;

    // Audit fields
    @Column(nullable = false, length = 100)
    @Builder.Default
    private String createdBy = "system";

    @Column(nullable = false, length = 100)
    @Builder.Default
    private String updatedBy = "system";

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    // Enums
    public enum AssignmentStatus {
        ASSIGNED,           // Just assigned to partner
        ACCEPTED,          // Partner accepted the assignment
        REJECTED,          // Partner rejected the assignment
        PICKED_UP,         // Partner picked up from shop
        IN_TRANSIT,        // On the way to customer
        DELIVERED,         // Successfully delivered
        COMPLETED,         // Assignment completed with payment
        CANCELLED          // Assignment cancelled
    }

    public enum AssignmentType {
        AUTO,              // Automatically assigned by system
        MANUAL             // Manually assigned by admin/shop owner
    }

    // Helper methods
    public boolean isActive() {
        return status == AssignmentStatus.ASSIGNED ||
               status == AssignmentStatus.ACCEPTED ||
               status == AssignmentStatus.PICKED_UP ||
               status == AssignmentStatus.IN_TRANSIT;
    }

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
        return status == AssignmentStatus.IN_TRANSIT || status == AssignmentStatus.PICKED_UP;
    }

    public boolean isCompleted() {
        return status == AssignmentStatus.COMPLETED ||
               status == AssignmentStatus.DELIVERED;
    }

    public void accept() {
        if (canBeAccepted()) {
            this.status = AssignmentStatus.ACCEPTED;
            this.acceptedAt = LocalDateTime.now();
        }
    }

    public void reject(String reason) {
        if (canBeRejected()) {
            this.status = AssignmentStatus.REJECTED;
            this.rejectedAt = LocalDateTime.now();
            this.rejectionReason = reason;
        }
    }

    public void markPickedUp() {
        if (canBePickedUp()) {
            this.status = AssignmentStatus.PICKED_UP;
            this.pickupTime = LocalDateTime.now();
        }
    }

    public void markInTransit() {
        if (status == AssignmentStatus.PICKED_UP) {
            this.status = AssignmentStatus.IN_TRANSIT;
        }
    }

    public void markDelivered() {
        if (canBeDelivered()) {
            this.status = AssignmentStatus.DELIVERED;
            this.deliveryCompletedAt = LocalDateTime.now();
        }
    }

    public void complete() {
        if (status == AssignmentStatus.DELIVERED) {
            this.status = AssignmentStatus.COMPLETED;
        }
    }
}