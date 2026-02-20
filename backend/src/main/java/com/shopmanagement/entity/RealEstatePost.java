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
@Table(name = "real_estate_posts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class RealEstatePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "property_type", nullable = false, length = 30)
    private PropertyType propertyType;

    @Enumerated(EnumType.STRING)
    @Column(name = "listing_type", nullable = false, length = 20)
    private ListingType listingType;

    @Column(precision = 15, scale = 2)
    private BigDecimal price;

    @Column(name = "area_sqft")
    private Integer areaSqft;

    @Column(name = "bedrooms")
    private Integer bedrooms;

    @Column(name = "bathrooms")
    private Integer bathrooms;

    @Column(length = 500)
    private String location;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    // Store multiple image URLs as comma-separated string (up to 5)
    @Column(name = "image_urls", length = 2500)
    private String imageUrls;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    @Column(name = "owner_user_id", nullable = false)
    private Long ownerUserId;

    @Column(name = "owner_name", length = 200)
    private String ownerName;

    @Column(name = "owner_phone", nullable = false, length = 20)
    private String ownerPhone;

    @Column(name = "views_count")
    @Builder.Default
    private Integer viewsCount = 0;

    @Column(name = "report_count")
    @Builder.Default
    private Integer reportCount = 0;

    @Column(name = "is_featured")
    @Builder.Default
    private Boolean isFeatured = false;

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

    public enum PropertyType {
        LAND,
        HOUSE,
        APARTMENT,
        VILLA,
        COMMERCIAL,
        PLOT,
        FARM_LAND,
        PG_HOSTEL
    }

    public enum ListingType {
        FOR_SALE,
        FOR_RENT
    }

    public enum PostStatus {
        PENDING_APPROVAL,
        APPROVED,
        REJECTED,
        SOLD,
        RENTED,
        FLAGGED,
        HOLD,
        HIDDEN,
        CORRECTION_REQUIRED,
        REMOVED,
        DELETED
    }
}
