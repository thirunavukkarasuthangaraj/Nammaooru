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
@Table(name = "farmer_products")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class FarmerProduct {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 1000)
    private String description;

    @Column(precision = 10, scale = 2)
    private BigDecimal price;

    @Column(length = 20)
    private String unit;

    // Store multiple image URLs as comma-separated string (up to 5)
    @Column(name = "image_urls", length = 2500)
    private String imageUrls;

    @Column(name = "seller_user_id", nullable = false)
    private Long sellerUserId;

    @Column(name = "seller_name", length = 200)
    private String sellerName;

    @Column(name = "seller_phone", nullable = false, length = 20)
    private String sellerPhone;

    @Column(length = 100)
    private String category;

    @Column(length = 200)
    private String location;

    @Column(precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(precision = 11, scale = 8)
    private BigDecimal longitude;

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
