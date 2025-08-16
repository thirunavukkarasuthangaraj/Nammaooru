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
@Table(name = "analytics")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Analytics {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "metric_name", nullable = false, length = 100)
    private String metricName;
    
    @Column(name = "metric_value", nullable = false)
    private BigDecimal metricValue;
    
    @Column(name = "metric_type", nullable = false, length = 50)
    @Enumerated(EnumType.STRING)
    private MetricType metricType;
    
    @Column(name = "period_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private PeriodType periodType;
    
    @Column(name = "period_start", nullable = false)
    private LocalDateTime periodStart;
    
    @Column(name = "period_end", nullable = false)
    private LocalDateTime periodEnd;
    
    @Column(name = "shop_id")
    private Long shopId;
    
    @Column(name = "user_id")
    private Long userId;
    
    @Column(name = "category", length = 100)
    private String category;
    
    @Column(name = "sub_category", length = 100)
    private String subCategory;
    
    @Column(name = "additional_data", columnDefinition = "TEXT")
    private String additionalData;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "created_by", length = 100)
    private String createdBy;
    
    @Column(name = "updated_by", length = 100)
    private String updatedBy;
    
    public enum MetricType {
        REVENUE, ORDER_COUNT, CUSTOMER_COUNT, CONVERSION_RATE, AVERAGE_ORDER_VALUE,
        PRODUCT_SALES, CUSTOMER_ACQUISITION, CUSTOMER_RETENTION, PAGE_VIEWS,
        BOUNCE_RATE, SESSION_DURATION, TRAFFIC_SOURCE, GEOGRAPHIC_DATA,
        INVENTORY_TURNOVER, PROFIT_MARGIN, CUSTOMER_SATISFACTION
    }
    
    public enum PeriodType {
        DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, CUSTOM
    }
}