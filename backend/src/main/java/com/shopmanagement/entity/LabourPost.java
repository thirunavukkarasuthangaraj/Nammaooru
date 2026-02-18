package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "labour_posts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class LabourPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, length = 20)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private LabourCategory category;

    @Column(length = 100)
    private String experience;

    @Column(length = 200)
    private String location;

    @Column(length = 1000)
    private String description;

    @Column(name = "image_urls", length = 1500)
    private String imageUrls;

    @Column(precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "seller_user_id", nullable = false)
    private Long sellerUserId;

    @Column(name = "seller_name", length = 200)
    private String sellerName;

    @Column(name = "featured")
    @Builder.Default
    private Boolean featured = false;

    @Column(name = "report_count")
    @Builder.Default
    private Integer reportCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    @Builder.Default
    private PostStatus status = PostStatus.PENDING_APPROVAL;

    @Column(name = "is_paid")
    @Builder.Default
    private Boolean isPaid = false;

    @Column(name = "valid_from")
    private LocalDateTime validFrom;

    @Column(name = "valid_to")
    private LocalDateTime validTo;

    @Column(name = "expiry_reminder_sent")
    @Builder.Default
    private Boolean expiryReminderSent = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum LabourCategory {
        PAINTER,
        CARPENTER,
        ELECTRICIAN,
        PLUMBER,
        CONTRACTOR,
        MASON,
        DRIVER,
        WELDER,
        MECHANIC,
        TAILOR,
        AC_TECHNICIAN,
        HELPER,
        BIKE_REPAIR,
        CAR_REPAIR,
        TYRE_PUNCTURE,
        GENERAL_LABOUR,
        OTHER
    }

    public enum PostStatus {
        PENDING_APPROVAL,
        APPROVED,
        REJECTED,
        SOLD,
        FLAGGED,
        HOLD,
        HIDDEN,
        CORRECTION_REQUIRED,
        REMOVED
    }
}
