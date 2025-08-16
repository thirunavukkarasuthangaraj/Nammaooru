package com.shopmanagement.service;

import com.shopmanagement.dto.analytics.AnalyticsRequest;
import com.shopmanagement.dto.analytics.AnalyticsResponse;
import com.shopmanagement.entity.Analytics;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.entity.User;
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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
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
    
    public AnalyticsResponse.DashboardMetrics getDashboardMetrics(AnalyticsRequest request) {
        log.info("Generating dashboard metrics for period: {} to {}", request.getStartDate(), request.getEndDate());
        
        LocalDateTime startDate = request.getStartDate();
        LocalDateTime endDate = request.getEndDate();
        
        // Calculate total metrics
        BigDecimal totalRevenue = analyticsRepository.getTotalRevenue(startDate, endDate);
        Long totalOrders = analyticsRepository.getTotalOrders(startDate, endDate);
        Long totalCustomers = analyticsRepository.getTotalCustomers(startDate, endDate);
        Long totalShops = shopRepository.count();
        BigDecimal averageOrderValue = analyticsRepository.getAverageOrderValue(startDate, endDate);
        Double conversionRate = analyticsRepository.getAverageConversionRate(startDate, endDate);
        
        // Calculate previous period for growth comparison
        long daysDiff = ChronoUnit.DAYS.between(startDate, endDate);
        LocalDateTime previousStart = startDate.minusDays(daysDiff);
        LocalDateTime previousEnd = startDate;
        
        BigDecimal previousRevenue = analyticsRepository.getTotalRevenue(previousStart, previousEnd);
        BigDecimal monthlyGrowth = calculateGrowthPercentage(totalRevenue, previousRevenue);
        
        // Get revenue data
        List<AnalyticsResponse.RevenueData> revenueData = getRevenueData(startDate, endDate);
        
        // Get order data
        List<AnalyticsResponse.OrderData> orderData = getOrderData(startDate, endDate);
        
        // Get category data
        List<AnalyticsResponse.CategoryData> categoryData = getCategoryData(startDate, endDate);
        
        // Get top shops
        List<AnalyticsResponse.ShopPerformance> topShops = getTopShops(startDate, endDate);
        
        // Get revenue by period
        Map<String, BigDecimal> revenueByPeriod = getRevenueByPeriod(startDate, endDate);
        Map<String, Long> ordersByPeriod = getOrdersByPeriod(startDate, endDate);
        
        return AnalyticsResponse.DashboardMetrics.builder()
                .totalRevenue(totalRevenue != null ? totalRevenue : BigDecimal.ZERO)
                .totalOrders(totalOrders != null ? totalOrders : 0L)
                .totalCustomers(totalCustomers != null ? totalCustomers : 0L)
                .totalShops(totalShops)
                .averageOrderValue(averageOrderValue != null ? averageOrderValue : BigDecimal.ZERO)
                .conversionRate(conversionRate != null ? conversionRate : 0.0)
                .monthlyGrowth(monthlyGrowth)
                .revenueData(revenueData)
                .orderData(orderData)
                .categoryData(categoryData)
                .topShops(topShops)
                .revenueByPeriod(revenueByPeriod)
                .ordersByPeriod(ordersByPeriod)
                .build();
    }
    
    public AnalyticsResponse.DashboardMetrics getShopDashboardMetrics(Long shopId, AnalyticsRequest request) {
        log.info("Generating shop dashboard metrics for shop: {} for period: {} to {}", shopId, request.getStartDate(), request.getEndDate());
        
        LocalDateTime startDate = request.getStartDate();
        LocalDateTime endDate = request.getEndDate();
        
        // Shop-specific metrics
        BigDecimal shopRevenue = analyticsRepository.getRevenueByShop(shopId, startDate, endDate);
        Long shopOrders = analyticsRepository.getOrdersByShop(shopId, startDate, endDate);
        Long shopCustomers = orderRepository.countOrdersByShop(shopId);
        
        // Calculate previous period for growth
        long daysDiff = ChronoUnit.DAYS.between(startDate, endDate);
        LocalDateTime previousStart = startDate.minusDays(daysDiff);
        LocalDateTime previousEnd = startDate;
        
        BigDecimal previousShopRevenue = analyticsRepository.getRevenueByShop(shopId, previousStart, previousEnd);
        BigDecimal monthlyGrowth = calculateGrowthPercentage(shopRevenue, previousShopRevenue);
        
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
        Long newCustomers = customerRepository.countCustomersCreatedBetween(startDate, endDate);
        Long returningCustomers = totalCustomers - newCustomers;
        
        Double retentionRate = totalCustomers > 0 ? (returningCustomers.doubleValue() / totalCustomers) * 100 : 0.0;
        BigDecimal totalRevenue = analyticsRepository.getTotalRevenue(startDate, endDate);
        BigDecimal averageLifetimeValue = totalCustomers > 0 ? 
                totalRevenue.divide(BigDecimal.valueOf(totalCustomers), 2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        
        return AnalyticsResponse.CustomerAnalytics.builder()
                .totalCustomers(totalCustomers)
                .newCustomers(newCustomers)
                .returningCustomers(returningCustomers)
                .retentionRate(retentionRate)
                .averageLifetimeValue(averageLifetimeValue)
                .build();
    }
    
    @Transactional
    public void generatePeriodAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        log.info("Generating analytics for period: {} to {} ({})", startDate, endDate, periodType);
        
        // Generate revenue analytics
        generateRevenueAnalytics(startDate, endDate, periodType);
        
        // Generate order analytics
        generateOrderAnalytics(startDate, endDate, periodType);
        
        // Generate customer analytics
        generateCustomerAnalytics(startDate, endDate, periodType);
        
        log.info("Analytics generation completed for period: {} to {}", startDate, endDate);
    }
    
    private void generateRevenueAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        // Total revenue
        BigDecimal totalRevenue = orderRepository.getRevenueByShopAndDateRange(null, startDate, endDate);
        if (totalRevenue != null && totalRevenue.compareTo(BigDecimal.ZERO) > 0) {
            saveAnalytics("Total Revenue", totalRevenue, Analytics.MetricType.REVENUE, periodType, startDate, endDate, null);
        }
        
        // Revenue by shop
        List<Object[]> shopRevenues = analyticsRepository.getShopPerformance(startDate, endDate);
        for (Object[] shopRevenue : shopRevenues) {
            Long shopId = (Long) shopRevenue[0];
            BigDecimal revenue = (BigDecimal) shopRevenue[1];
            if (revenue != null && revenue.compareTo(BigDecimal.ZERO) > 0) {
                saveAnalytics("Shop Revenue", revenue, Analytics.MetricType.REVENUE, periodType, startDate, endDate, shopId);
            }
        }
    }
    
    private void generateOrderAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        // Total orders
        Long totalOrders = orderRepository.countAnalyticsByPeriod(startDate, endDate);
        if (totalOrders != null && totalOrders > 0) {
            saveAnalytics("Total Orders", BigDecimal.valueOf(totalOrders), Analytics.MetricType.ORDER_COUNT, periodType, startDate, endDate, null);
        }
        
        // Orders by shop
        List<Long> shopIds = analyticsRepository.findDistinctShopIds();
        for (Long shopId : shopIds) {
            Long shopOrders = orderRepository.countOrdersByShopAndStatus(shopId, null);
            if (shopOrders != null && shopOrders > 0) {
                saveAnalytics("Shop Orders", BigDecimal.valueOf(shopOrders), Analytics.MetricType.ORDER_COUNT, periodType, startDate, endDate, shopId);
            }
        }
    }
    
    private void generateCustomerAnalytics(LocalDateTime startDate, LocalDateTime endDate, Analytics.PeriodType periodType) {
        // Total customers
        Long totalCustomers = customerRepository.count();
        if (totalCustomers != null && totalCustomers > 0) {
            saveAnalytics("Total Customers", BigDecimal.valueOf(totalCustomers), Analytics.MetricType.CUSTOMER_COUNT, periodType, startDate, endDate, null);
        }
        
        // New customers in period
        Long newCustomers = customerRepository.countCustomersCreatedBetween(startDate, endDate);
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
    
    private List<AnalyticsResponse.RevenueData> getRevenueData(LocalDateTime startDate, LocalDateTime endDate) {
        List<Object[]> dailyRevenue = analyticsRepository.getDailyRevenue(startDate, endDate);
        return dailyRevenue.stream().map(data -> {
            LocalDateTime date = (LocalDateTime) data[0];
            BigDecimal revenue = (BigDecimal) data[1];
            return AnalyticsResponse.RevenueData.builder()
                    .period(date.format(DateTimeFormatter.ofPattern("dd/MM")))
                    .revenue(revenue)
                    .date(date)
                    .build();
        }).collect(Collectors.toList());
    }
    
    private List<AnalyticsResponse.OrderData> getOrderData(LocalDateTime startDate, LocalDateTime endDate) {
        List<Object[]> dailyOrders = analyticsRepository.getDailyRevenue(startDate, endDate); // Reuse for now
        return dailyOrders.stream().map(data -> {
            LocalDateTime date = (LocalDateTime) data[0];
            return AnalyticsResponse.OrderData.builder()
                    .period(date.format(DateTimeFormatter.ofPattern("dd/MM")))
                    .orderCount(10L) // Placeholder
                    .date(date)
                    .build();
        }).collect(Collectors.toList());
    }
    
    private List<AnalyticsResponse.CategoryData> getCategoryData(LocalDateTime startDate, LocalDateTime endDate) {
        List<Object[]> categoryRevenue = analyticsRepository.getRevenueByCategory(startDate, endDate);
        return categoryRevenue.stream().map(data -> {
            String category = (String) data[0];
            BigDecimal revenue = (BigDecimal) data[1];
            return AnalyticsResponse.CategoryData.builder()
                    .categoryName(category)
                    .revenue(revenue)
                    .build();
        }).collect(Collectors.toList());
    }
    
    private List<AnalyticsResponse.ShopPerformance> getTopShops(LocalDateTime startDate, LocalDateTime endDate) {
        List<Object[]> shopPerformance = analyticsRepository.getShopPerformance(startDate, endDate);
        return shopPerformance.stream().limit(10).map(data -> {
            Long shopId = (Long) data[0];
            BigDecimal revenue = (BigDecimal) data[1];
            Long orders = ((BigDecimal) data[2]).longValue();
            
            Shop shop = shopRepository.findById(shopId).orElse(null);
            String shopName = shop != null ? shop.getName() : "Unknown Shop";
            String shopOwner = shop != null ? shop.getOwnerName() : "Unknown Owner";
            
            return AnalyticsResponse.ShopPerformance.builder()
                    .shopId(shopId)
                    .shopName(shopName)
                    .shopOwner(shopOwner)
                    .revenue(revenue)
                    .orderCount(orders)
                    .build();
        }).collect(Collectors.toList());
    }
    
    private Map<String, BigDecimal> getRevenueByPeriod(LocalDateTime startDate, LocalDateTime endDate) {
        List<Object[]> monthlyRevenue = analyticsRepository.getMonthlyRevenue(startDate, endDate);
        Map<String, BigDecimal> result = new HashMap<>();
        for (Object[] data : monthlyRevenue) {
            LocalDateTime month = (LocalDateTime) data[0];
            BigDecimal revenue = (BigDecimal) data[1];
            result.put(month.format(DateTimeFormatter.ofPattern("MMM yyyy")), revenue);
        }
        return result;
    }
    
    private Map<String, Long> getOrdersByPeriod(LocalDateTime startDate, LocalDateTime endDate) {
        // Placeholder implementation
        Map<String, Long> result = new HashMap<>();
        result.put("Jan 2024", 150L);
        result.put("Feb 2024", 200L);
        result.put("Mar 2024", 180L);
        return result;
    }
    
    private BigDecimal calculateGrowthPercentage(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return current.subtract(previous)
                .divide(previous, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP);
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