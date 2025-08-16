package com.shopmanagement.repository;

import com.shopmanagement.entity.Analytics;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AnalyticsRepository extends JpaRepository<Analytics, Long> {
    
    // Find analytics by metric type
    List<Analytics> findByMetricType(Analytics.MetricType metricType);
    Page<Analytics> findByMetricType(Analytics.MetricType metricType, Pageable pageable);
    
    // Find analytics by period type
    List<Analytics> findByPeriodType(Analytics.PeriodType periodType);
    Page<Analytics> findByPeriodType(Analytics.PeriodType periodType, Pageable pageable);
    
    // Find analytics by shop
    List<Analytics> findByShopId(Long shopId);
    Page<Analytics> findByShopId(Long shopId, Pageable pageable);
    
    // Find analytics by date range
    @Query("SELECT a FROM Analytics a WHERE a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    List<Analytics> findByDateRange(@Param("startDate") LocalDateTime startDate, 
                                   @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT a FROM Analytics a WHERE a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Page<Analytics> findByDateRange(@Param("startDate") LocalDateTime startDate, 
                                   @Param("endDate") LocalDateTime endDate, 
                                   Pageable pageable);
    
    // Find analytics by shop and date range
    @Query("SELECT a FROM Analytics a WHERE a.shopId = :shopId AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    List<Analytics> findByShopIdAndDateRange(@Param("shopId") Long shopId,
                                            @Param("startDate") LocalDateTime startDate,
                                            @Param("endDate") LocalDateTime endDate);
    
    // Find analytics by metric type and date range
    @Query("SELECT a FROM Analytics a WHERE a.metricType = :metricType AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    List<Analytics> findByMetricTypeAndDateRange(@Param("metricType") Analytics.MetricType metricType,
                                                @Param("startDate") LocalDateTime startDate,
                                                @Param("endDate") LocalDateTime endDate);
    
    // Find analytics by category
    List<Analytics> findByCategory(String category);
    Page<Analytics> findByCategory(String category, Pageable pageable);
    
    // Revenue analytics queries
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = 'REVENUE' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    BigDecimal getTotalRevenue(@Param("startDate") LocalDateTime startDate, 
                              @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = 'REVENUE' AND a.shopId = :shopId AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    BigDecimal getRevenueByShop(@Param("shopId") Long shopId,
                               @Param("startDate") LocalDateTime startDate,
                               @Param("endDate") LocalDateTime endDate);
    
    // Order analytics queries
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = 'ORDER_COUNT' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Long getTotalOrders(@Param("startDate") LocalDateTime startDate, 
                       @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = 'ORDER_COUNT' AND a.shopId = :shopId AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Long getOrdersByShop(@Param("shopId") Long shopId,
                        @Param("startDate") LocalDateTime startDate,
                        @Param("endDate") LocalDateTime endDate);
    
    // Customer analytics queries
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = 'CUSTOMER_COUNT' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Long getTotalCustomers(@Param("startDate") LocalDateTime startDate, 
                          @Param("endDate") LocalDateTime endDate);
    
    // Average order value
    @Query("SELECT AVG(a.metricValue) FROM Analytics a WHERE a.metricType = 'AVERAGE_ORDER_VALUE' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    BigDecimal getAverageOrderValue(@Param("startDate") LocalDateTime startDate, 
                                   @Param("endDate") LocalDateTime endDate);
    
    // Conversion rate
    @Query("SELECT AVG(a.metricValue) FROM Analytics a WHERE a.metricType = 'CONVERSION_RATE' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Double getAverageConversionRate(@Param("startDate") LocalDateTime startDate, 
                                   @Param("endDate") LocalDateTime endDate);
    
    // Monthly revenue data
    @Query("SELECT DATE_TRUNC('month', a.periodStart) as month, SUM(a.metricValue) as revenue " +
           "FROM Analytics a WHERE a.metricType = 'REVENUE' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate " +
           "GROUP BY DATE_TRUNC('month', a.periodStart) ORDER BY month")
    List<Object[]> getMonthlyRevenue(@Param("startDate") LocalDateTime startDate,
                                    @Param("endDate") LocalDateTime endDate);
    
    // Daily revenue data
    @Query("SELECT DATE_TRUNC('day', a.periodStart) as day, SUM(a.metricValue) as revenue " +
           "FROM Analytics a WHERE a.metricType = 'REVENUE' AND a.periodStart >= :startDate AND a.periodEnd <= :endDate " +
           "GROUP BY DATE_TRUNC('day', a.periodStart) ORDER BY day")
    List<Object[]> getDailyRevenue(@Param("startDate") LocalDateTime startDate,
                                  @Param("endDate") LocalDateTime endDate);
    
    // Category wise revenue
    @Query("SELECT a.category, SUM(a.metricValue) as revenue " +
           "FROM Analytics a WHERE a.metricType = 'REVENUE' AND a.category IS NOT NULL " +
           "AND a.periodStart >= :startDate AND a.periodEnd <= :endDate " +
           "GROUP BY a.category ORDER BY revenue DESC")
    List<Object[]> getRevenueByCategory(@Param("startDate") LocalDateTime startDate,
                                       @Param("endDate") LocalDateTime endDate);
    
    // Shop performance data
    @Query("SELECT a.shopId, SUM(CASE WHEN a.metricType = 'REVENUE' THEN a.metricValue ELSE 0 END) as revenue, " +
           "SUM(CASE WHEN a.metricType = 'ORDER_COUNT' THEN a.metricValue ELSE 0 END) as orders " +
           "FROM Analytics a WHERE a.shopId IS NOT NULL AND a.periodStart >= :startDate AND a.periodEnd <= :endDate " +
           "GROUP BY a.shopId ORDER BY revenue DESC")
    List<Object[]> getShopPerformance(@Param("startDate") LocalDateTime startDate,
                                     @Param("endDate") LocalDateTime endDate);
    
    // Growth calculation queries
    @Query("SELECT SUM(a.metricValue) FROM Analytics a WHERE a.metricType = :metricType " +
           "AND a.periodStart >= :previousStartDate AND a.periodEnd <= :previousEndDate")
    BigDecimal getPreviousPeriodValue(@Param("metricType") Analytics.MetricType metricType,
                                     @Param("previousStartDate") LocalDateTime previousStartDate,
                                     @Param("previousEndDate") LocalDateTime previousEndDate);
    
    // Latest analytics by metric type
    @Query("SELECT a FROM Analytics a WHERE a.metricType = :metricType ORDER BY a.createdAt DESC")
    List<Analytics> getLatestByMetricType(@Param("metricType") Analytics.MetricType metricType, Pageable pageable);
    
    // Find distinct categories
    @Query("SELECT DISTINCT a.category FROM Analytics a WHERE a.category IS NOT NULL ORDER BY a.category")
    List<String> findDistinctCategories();
    
    // Find distinct shops with analytics
    @Query("SELECT DISTINCT a.shopId FROM Analytics a WHERE a.shopId IS NOT NULL ORDER BY a.shopId")
    List<Long> findDistinctShopIds();
    
    // Delete old analytics data
    @Query("DELETE FROM Analytics a WHERE a.createdAt < :cutoffDate")
    void deleteOldAnalytics(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    // Count analytics by period
    @Query("SELECT COUNT(a) FROM Analytics a WHERE a.periodStart >= :startDate AND a.periodEnd <= :endDate")
    Long countAnalyticsByPeriod(@Param("startDate") LocalDateTime startDate,
                               @Param("endDate") LocalDateTime endDate);
}