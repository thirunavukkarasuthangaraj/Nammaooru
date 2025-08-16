package com.shopmanagement.dto.analytics;

import com.shopmanagement.entity.Analytics;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyticsResponse {
    
    private Long id;
    private String metricName;
    private BigDecimal metricValue;
    private Analytics.MetricType metricType;
    private Analytics.PeriodType periodType;
    private LocalDateTime periodStart;
    private LocalDateTime periodEnd;
    private Long shopId;
    private String shopName;
    private Long userId;
    private String userName;
    private String category;
    private String subCategory;
    private String additionalData;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Helper fields
    private String formattedValue;
    private String periodLabel;
    private Double growthPercentage;
    private String trendDirection;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DashboardMetrics {
        private BigDecimal totalRevenue;
        private Long totalOrders;
        private Long totalCustomers;
        private Long totalShops;
        private BigDecimal averageOrderValue;
        private Double conversionRate;
        private Double customerRetentionRate;
        private BigDecimal monthlyGrowth;
        private List<RevenueData> revenueData;
        private List<OrderData> orderData;
        private List<CategoryData> categoryData;
        private List<ShopPerformance> topShops;
        private List<ProductPerformance> topProducts;
        private Map<String, BigDecimal> revenueByPeriod;
        private Map<String, Long> ordersByPeriod;
        private Map<String, Double> conversionByPeriod;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class RevenueData {
        private String period;
        private BigDecimal revenue;
        private BigDecimal previousRevenue;
        private Double growthPercentage;
        private LocalDateTime date;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OrderData {
        private String period;
        private Long orderCount;
        private Long previousOrderCount;
        private Double growthPercentage;
        private LocalDateTime date;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CategoryData {
        private String categoryName;
        private BigDecimal revenue;
        private Long orderCount;
        private Double marketShare;
        private Double growthPercentage;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ShopPerformance {
        private Long shopId;
        private String shopName;
        private String shopOwner;
        private BigDecimal revenue;
        private Long orderCount;
        private Long customerCount;
        private Double rating;
        private Double growthPercentage;
        private String status;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ProductPerformance {
        private Long productId;
        private String productName;
        private String category;
        private Long quantitySold;
        private BigDecimal revenue;
        private Double averageRating;
        private Integer stockLevel;
        private Double conversionRate;
        private String trendDirection;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CustomerAnalytics {
        private Long totalCustomers;
        private Long newCustomers;
        private Long returningCustomers;
        private Double retentionRate;
        private BigDecimal averageLifetimeValue;
        private Double churnRate;
        private Map<String, Long> customersBySegment;
        private Map<String, BigDecimal> revenueBySegment;
        private List<CustomerBehavior> customerBehavior;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CustomerBehavior {
        private String segment;
        private Double averageOrderValue;
        private Double orderFrequency;
        private String preferredCategory;
        private String preferredPaymentMethod;
        private Integer averageSessionDuration;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class GeographicData {
        private String region;
        private String city;
        private String state;
        private Long customerCount;
        private BigDecimal revenue;
        private Long orderCount;
        private Double averageOrderValue;
        private Double marketPenetration;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TrafficAnalytics {
        private Long totalPageViews;
        private Long uniqueVisitors;
        private Double bounceRate;
        private Integer averageSessionDuration;
        private Map<String, Long> trafficSources;
        private Map<String, Double> conversionBySource;
        private List<PagePerformance> topPages;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PagePerformance {
        private String pagePath;
        private String pageTitle;
        private Long pageViews;
        private Double bounceRate;
        private Integer averageTimeOnPage;
        private Double exitRate;
        private Double conversionRate;
    }
}