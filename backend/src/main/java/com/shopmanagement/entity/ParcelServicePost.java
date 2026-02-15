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
@Table(name = "parcel_service_posts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class ParcelServicePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "service_name", nullable = false, length = 200)
    private String serviceName;

    @Column(nullable = false, length = 20)
    private String phone;

    @Column(name = "from_location", length = 200)
    private String fromLocation;

    @Column(name = "to_location", length = 200)
    private String toLocation;

    @Column(name = "price_info", length = 200)
    private String priceInfo;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_type", nullable = false, length = 30)
    private ServiceType serviceType;

    @Column(length = 500)
    private String address;

    @Column(length = 200)
    private String timings;

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

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum ServiceType {
        DOOR_TO_DOOR,
        PICKUP_POINT,
        BOTH
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
