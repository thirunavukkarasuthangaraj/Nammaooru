package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "jobs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class JobPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_title", nullable = false, length = 200)
    private String jobTitle;

    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;

    @Column(nullable = false, length = 20)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private JobCategory category;

    @Enumerated(EnumType.STRING)
    @Column(name = "job_type", length = 30)
    @Builder.Default
    private JobType jobType = JobType.FULL_TIME;

    @Column(length = 100)
    private String salary;

    @Column(name = "salary_type", length = 20)
    @Builder.Default
    private String salaryType = "MONTHLY";

    @Column
    private Integer vacancies;

    @Column(length = 300)
    private String location;

    @Column(length = 1000)
    private String description;

    @Column(length = 1000)
    private String requirements;

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

    @Column(name = "is_featured")
    @Builder.Default
    private Boolean featured = false;

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

    public enum JobCategory {
        SHOP_WORKER, SALES_PERSON, DELIVERY_BOY, SECURITY, CASHIER,
        RECEPTIONIST, ACCOUNTANT, DRIVER, COOK, HELPER, TEACHER,
        NURSE, TAILOR, CLEANER, WATCHMAN, FARM_WORKER, COMPUTER_OPERATOR,
        PEON, MANAGER, OTHER
    }

    public enum JobType {
        FULL_TIME, PART_TIME, CONTRACT, DAILY_WAGE, INTERNSHIP
    }

    public enum PostStatus {
        PENDING_APPROVAL, APPROVED, REJECTED, EXPIRED, DELETED, UNAVAILABLE
    }
}
