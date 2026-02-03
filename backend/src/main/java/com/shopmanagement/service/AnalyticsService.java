package com.shopmanagement.service;

import com.shopmanagement.dto.analytics.AnalyticsRequest;
import com.shopmanagement.dto.analytics.AnalyticsResponse;
import com.shopmanagement.entity.Analytics;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.repository.AnalyticsRepository;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final AnalyticsRepository analyticsRepository;
    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final ShopRepository shopRepository;
    private final UserRepository userRepository;

    /**
     * Get dashboard metrics by querying real data from orders, customers, and shops tables.
     */
    public AnalyticsResponse.DashboardMetrics getDashboardMetrics(AnalyticsRequest request) {
        log.info("Generating dashboard metrics for period: {} to {}", request.getStartDate(), request.getEndDate());

        LocalDateTime startDate = request.getStartDate();
        LocalDateTime endDate = request.getEndDate();

        // Query real data from orders table
        BigDecimal totalRevenue = orderRepository.getTotalRevenueByDateRange(startDate, endDate);
        Long totalOrders = orderRepository.countAnalyticsByPeriod(startDate, endDate);
        Long totalCustomers = orderRepository.countDistinctCustomersByDateRange(startDate, endDate);
        Long totalShops = shopRepository.countByIsActiveTrue();
        BigDecimal averageOrderValue = orderRepository.getAvgOrderValueByDateRange(startDate, endDate);

        // Calculate previous period for growth comparison
        long daysDiff = Math.max(ChronoUnit.DAYS.between(startDate, endDate), 1);
        LocalDateTime previousStart = startDate.minusDays(daysDiff);
        LocalDateTime previousEnd = startDate;

        BigDecimal previousRevenue = orderRepository.getTotalRevenueByDateRange(previousStart, previousEnd);
        BigDecimal monthlyGrowth = calculateGrowthPercentage(
                totalRevenue != null ? totalRevenue : BigDecimal.ZERO,
                previousRevenue != null ? previousRevenue : BigDecimal.ZERO
        );

        // Calculate customer retention rate
        Long totalAllCustomers = customerRepository.count();
        Long newCustomersInPeriod = customerRepository.countCustomersInDateRange(startDate, endDate);
        Double retentionRate = totalAllCustomers > 0 && newCustomersInPeriod != null ?
                ((totalAllCustomers - newCustomersInPeriod) * 100.0 / totalAllCustomers) : 0.0;

        // Get detailed data
        List<AnalyticsResponse.RevenueData> revenueData = getRevenueDataFromOrders(startDate, endDate);
        List<AnalyticsResponse.OrderData> orderData = getOrderDataFromOrders(startDate, endDate);
        List<AnalyticsResponse.ShopPerformance> topShops = getTopShopsFromOrders(startDate, endDate);
        Map<String, BigDecimal> revenueByPeriod = getRevenueByPeriodFromOrders(startDate, endDate);
        Map<String, Long> ordersByPeriod = getOrdersByPeriodFromOrders(startDate, endDate);

        return AnalyticsResponse.DashboardMetrics.builder()
                .totalRevenue(totalRevenue != null ? totalRevenue : BigDecimal.ZERO)
                .totalOrders(totalOrders != null ? totalOrders : 0L)
                .totalCustomers(totalCustomers != null ? totalCustomers : 0L)
                .totalShops(totalShops)
                .averageOrderValue(averageOrderValue != null ? averageOrderValue : BigDecimal.ZERO)
                .conversionRate(0.0) // No web traffic data available
                .customerRetentionRate(retentionRate)
                .monthlyGrowth(monthlyGrowth)
                .revenueData(revenueData)
                .orderData(orderData)
                .topShops(topShops)
                .revenueByPeriod(revenueByPeriod)
                .ordersByPeriod(ordersByPeriod)
                .build();
    }

    /**
     * Get shop-specific dashboard metrics from real order data.
     */
    public AnalyticsResponse.DashboardMetrics getShopDashboardMetrics(Long shopId, AnalyticsRequest request) {
        log.info("Generating shop dashboard metrics for shop: {} for period: {} to {}", shopId, request.getStartDate(), request.getEndDate());

        LocalDateTime startDate = request.getStartDate();
        LocalDateTime endDate = request.getEndDate();

        // Shop-specific metrics from orders table
        BigDecimal shopRevenue = orderRepository.getShopRevenueInDateRange(shopId, startDate, endDate);
        Long shopOrders = orderRepository.countOrdersByShopInDateRange(shopId, startDate, endDate);
        Long shopCustomers = orderRepository.countDistinctCustomersByShopInDateRange(shopId, startDate, endDate);

        // Calculate previous period for growth
        long daysDiff = Math.max(ChronoUnit.DAYS.between(startDate, endDate), 1);
        LocalDateTime previousStart = startDate.minusDays(daysDiff);
        LocalDateTime previousEnd = startDate;

        BigDecimal previousShopRevenue = orderRepository.getShopRevenueInDateRange(shopId, previousStart, previousEnd);
        BigDecimal monthlyGrowth = calculateGrowthPercentage(
                shopRevenue != null ? shopRevenue : BigDecimal.ZERO,
                previousShopRevenue != null ? previousShopRevenue : BigDecimal.ZERO
        );

        return AnalyticsResponse.DashboardMetrics.builder()
                .totalRevenue(shopRevenue != null ? shopRevenue : BigDecimal.ZERO)
                .totalOrders(shopOrders != null ? shopOrders : 0L)
                .totalCustomers(shopCustomers != null ? shopCustomers : 0L)
                .monthlyGrowth(monthlyGrowth)
                .build();
    }

    public AnalyticsResponse.CustomerAnalytics getCustomerAnalytics(AnalyticsRequest request) {
        log.info("Generating customer analytics for period: {} to {}", request.getStartDate(), request.getEndDate());

        LocalDateTime startDate = request.getStartDate();
        LocalDateTime endDate = request.getEndDate();

        // Customer metrics
        Long totalCustomers = customerRepository.count();
        Long newCustomers = customerRepository.countCustomersInDateRange(startDate, endDate);
        Long returningCustomers = totalCustomers - (newCustomers != null ? newCustomers : 0L);

        Double retentionRate = totalCustomers > 0 ? (returningCustomers.doubleValue() / totalCustomers) * 100 : 0.0;
        BigDecimal totalRevenue = orderRepository.getTotalRevenueByDateRange(startDate, endDate);
        BigDecimal averageLifetimeValue = totalCustomers > 0 && totalRevenue != null ?
                totalRevenue.divide(BigDecimal.valueOf(totalCustomers), 2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

        return AnalyticsResponse.CustomerAnalytics.builder()
                .totalCustomers(totalCustomers)
                .newCustomers(newCustomers != null ? newCustomers : 0L)
                .returningCustomers(returningCustomers)
                .retentionRate(retentionRate)
                .averageLifetimeValue(averageLifetimeValue)
                .build();
    }

    @Transactional
    public void generatePeriodAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        log.info("Generating analytics for period: {} to {} ({})", startDate, endDate, periodType);

        generateRevenueAnalytics(startDate, endDate, periodType);
        generateOrderAnalytics(startDate, endDate, periodType);
        generateCustomerAnalytics(startDate, endDate, periodType);

        log.info("Analytics generation completed for period: {} to {}", startDate, endDate);
    }

    // ============ Private helper methods for real data queries ============

    /**
     * Get daily revenue data from orders table.
     */
    private List<AnalyticsResponse.RevenueData> getRevenueDataFromOrders(LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Object[]> dailyRevenue = orderRepository.getDailyRevenueAll(startDate, endDate);
            List<AnalyticsResponse.RevenueData> result = new ArrayList<>();
            BigDecimal previousRevenue = null;

            for (Object[] data : dailyRevenue) {
                LocalDateTime date = toLocalDateTime(data[0]);
                BigDecimal revenue = toBigDecimal(data[1]);

                Double growth = null;
                if (previousRevenue != null && previousRevenue.compareTo(BigDecimal.ZERO) > 0) {
                    growth = revenue.subtract(previousRevenue)
                            .divide(previousRevenue, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .doubleValue();
                }

                result.add(AnalyticsResponse.RevenueData.builder()
                        .period(date.format(DateTimeFormatter.ofPattern("dd/MM")))
                        .revenue(revenue)
                        .previousRevenue(previousRevenue)
                        .growthPercentage(growth)
                        .date(date)
                        .build());

                previousRevenue = revenue;
            }
            return result;
        } catch (Exception e) {
            log.warn("Error getting daily revenue data: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Get daily order count data from orders table.
     */
    private List<AnalyticsResponse.OrderData> getOrderDataFromOrders(LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Object[]> dailyOrders = orderRepository.getDailyOrderCountAll(startDate, endDate);
            List<AnalyticsResponse.OrderData> result = new ArrayList<>();
            Long previousCount = null;

            for (Object[] data : dailyOrders) {
                LocalDateTime date = toLocalDateTime(data[0]);
                Long count = toLong(data[1]);

                Double growth = null;
                if (previousCount != null && previousCount > 0) {
                    growth = ((count - previousCount) * 100.0) / previousCount;
                }

                result.add(AnalyticsResponse.OrderData.builder()
                        .period(date.format(DateTimeFormatter.ofPattern("dd/MM")))
                        .orderCount(count)
                        .previousOrderCount(previousCount)
                        .growthPercentage(growth)
                        .date(date)
                        .build());

                previousCount = count;
            }
            return result;
        } catch (Exception e) {
            log.warn("Error getting daily order data: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Get top shops ranked by revenue from orders table.
     */
    private List<AnalyticsResponse.ShopPerformance> getTopShopsFromOrders(LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Object[]> shopData = orderRepository.getTopShopsByRevenueInDateRange(startDate, endDate);
            return shopData.stream().limit(10).map(data -> {
                Long shopId = (Long) data[0];
                BigDecimal revenue = toBigDecimal(data[1]);
                Long orders = toLong(data[2]);
                Long customers = toLong(data[3]);

                Shop shop = shopRepository.findById(shopId).orElse(null);
                String shopName = shop != null ? shop.getName() : "Shop #" + shopId;
                String shopOwner = shop != null ? shop.getOwnerName() : "";
                Double rating = shop != null && shop.getRating() != null ? shop.getRating().doubleValue() : 0.0;
                String status = shop != null ? (shop.getIsActive() ? "ACTIVE" : "INACTIVE") : "UNKNOWN";

                return AnalyticsResponse.ShopPerformance.builder()
                        .shopId(shopId)
                        .shopName(shopName)
                        .shopOwner(shopOwner)
                        .revenue(revenue)
                        .orderCount(orders)
                        .customerCount(customers)
                        .rating(rating)
                        .status(status)
                        .build();
            }).collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Error getting top shops data: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Get monthly revenue breakdown from orders table.
     */
    private Map<String, BigDecimal> getRevenueByPeriodFromOrders(LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Object[]> monthlyRevenue = orderRepository.getMonthlyRevenueAll(startDate, endDate);
            Map<String, BigDecimal> result = new LinkedHashMap<>();
            for (Object[] data : monthlyRevenue) {
                LocalDateTime month = toLocalDateTime(data[0]);
                BigDecimal revenue = toBigDecimal(data[1]);
                result.put(month.format(DateTimeFormatter.ofPattern("MMM yyyy")), revenue);
            }
            return result;
        } catch (Exception e) {
            log.warn("Error getting monthly revenue data: {}", e.getMessage());
            return new HashMap<>();
        }
    }

    /**
     * Get monthly order count breakdown from orders table.
     */
    private Map<String, Long> getOrdersByPeriodFromOrders(LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Object[]> monthlyOrders = orderRepository.getMonthlyOrderCountAll(startDate, endDate);
            Map<String, Long> result = new LinkedHashMap<>();
            for (Object[] data : monthlyOrders) {
                LocalDateTime month = toLocalDateTime(data[0]);
                Long count = toLong(data[1]);
                result.put(month.format(DateTimeFormatter.ofPattern("MMM yyyy")), count);
            }
            return result;
        } catch (Exception e) {
            log.warn("Error getting monthly order data: {}", e.getMessage());
            return new HashMap<>();
        }
    }

    // ============ Analytics table generation (for pre-computed data) ============

    private void generateRevenueAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        BigDecimal totalRevenue = orderRepository.getTotalRevenueByDateRange(startDate, endDate);
        if (totalRevenue != null && totalRevenue.compareTo(BigDecimal.ZERO) > 0) {
            saveAnalytics("Total Revenue", totalRevenue, Analytics.MetricType.REVENUE, periodType, startDate, endDate, null);
        }
    }

    private void generateOrderAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        Long totalOrders = orderRepository.countAnalyticsByPeriod(startDate, endDate);
        if (totalOrders != null && totalOrders > 0) {
            saveAnalytics("Total Orders", BigDecimal.valueOf(totalOrders), Analytics.MetricType.ORDER_COUNT, periodType, startDate, endDate, null);
        }
    }

    private void generateCustomerAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        Long totalCustomers = customerRepository.count();
        if (totalCustomers > 0) {
            saveAnalytics("Total Customers", BigDecimal.valueOf(totalCustomers), Analytics.MetricType.CUSTOMER_COUNT, periodType, startDate, endDate, null);
        }

        Long newCustomers = customerRepository.countCustomersInDateRange(startDate, endDate);
        if (newCustomers != null && newCustomers > 0) {
            saveAnalytics("New Customers", BigDecimal.valueOf(newCustomers), Analytics.MetricType.CUSTOMER_ACQUISITION, periodType, startDate, endDate, null);
        }
    }

    private void saveAnalytics(String metricName, BigDecimal metricValue, Analytics.MetricType metricType,
                              Analytics.PeriodType periodType, LocalDateTime startDate, LocalDateTime endDate, Long shopId) {
        Analytics analytics = Analytics.builder()
                .metricName(metricName)
                .metricValue(metricValue)
                .metricType(metricType)
                .periodType(periodType)
                .periodStart(startDate)
                .periodEnd(endDate)
                .shopId(shopId)
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();

        analyticsRepository.save(analytics);
    }

    // ============ Utility methods ============

    private BigDecimal calculateGrowthPercentage(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return current.subtract(previous)
                .divide(previous, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Convert native query result to LocalDateTime (handles Timestamp from PostgreSQL).
     */
    private LocalDateTime toLocalDateTime(Object value) {
        if (value instanceof LocalDateTime) {
            return (LocalDateTime) value;
        } else if (value instanceof Timestamp) {
            return ((Timestamp) value).toLocalDateTime();
        } else if (value instanceof java.sql.Date) {
            return ((java.sql.Date) value).toLocalDate().atStartOfDay();
        }
        return LocalDateTime.now();
    }

    /**
     * Convert native query result to BigDecimal.
     */
    private BigDecimal toBigDecimal(Object value) {
        if (value instanceof BigDecimal) {
            return (BigDecimal) value;
        } else if (value instanceof Number) {
            return BigDecimal.valueOf(((Number) value).doubleValue());
        }
        return BigDecimal.ZERO;
    }

    /**
     * Convert native query result to Long.
     */
    private Long toLong(Object value) {
        if (value instanceof Long) {
            return (Long) value;
        } else if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        return 0L;
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }

    public Page<Analytics> getAnalytics(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return analyticsRepository.findAll(pageable);
    }

    public List<String> getAvailableCategories() {
        return analyticsRepository.findDistinctCategories();
    }

    public List<Analytics.MetricType> getAvailableMetricTypes() {
        return List.of(Analytics.MetricType.values());
    }

    public List<Analytics.PeriodType> getAvailablePeriodTypes() {
        return List.of(Analytics.PeriodType.values());
    }
}
