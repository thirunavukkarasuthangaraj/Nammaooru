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
@Table(name = "marketplace_posts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class MarketplacePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 1000)
    private String description;

    @Column(precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "voice_url", length = 500)
    private String voiceUrl;

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

    public enum PostStatus {
        PENDING_APPROVAL,
        APPROVED,
        REJECTED,
        SOLD,
        FLAGGED
    }
}
