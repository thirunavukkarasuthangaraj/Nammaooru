package com.shopmanagement.controller;

import com.shopmanagement.dto.analytics.AnalyticsRequest;
import com.shopmanagement.dto.analytics.AnalyticsResponse;
import com.shopmanagement.entity.Analytics;
import com.shopmanagement.service.AnalyticsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
public class AnalyticsController {
    
    private final AnalyticsService analyticsService;
    
    @PostMapping("/dashboard")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<AnalyticsResponse.DashboardMetrics> getDashboardMetrics(@Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching dashboard metrics for period: {} to {}", request.getStartDate(), request.getEndDate());
        AnalyticsResponse.DashboardMetrics metrics = analyticsService.getDashboardMetrics(request);
        return ResponseEntity.ok(metrics);
    }
    
    @PostMapping("/dashboard/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<AnalyticsResponse.DashboardMetrics> getShopDashboardMetrics(
            @PathVariable Long shopId, 
            @Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching shop dashboard metrics for shop: {} for period: {} to {}", shopId, request.getStartDate(), request.getEndDate());
        AnalyticsResponse.DashboardMetrics metrics = analyticsService.getShopDashboardMetrics(shopId, request);
        return ResponseEntity.ok(metrics);
    }
    
    @PostMapping("/customers")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<AnalyticsResponse.CustomerAnalytics> getCustomerAnalytics(@Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching customer analytics for period: {} to {}", request.getStartDate(), request.getEndDate());
        AnalyticsResponse.CustomerAnalytics analytics = analyticsService.getCustomerAnalytics(request);
        return ResponseEntity.ok(analytics);
    }
    
    @PostMapping("/generate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> generateAnalytics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam Analytics.PeriodType periodType) {
        log.info("Generating analytics for period: {} to {} ({})", startDate, endDate, periodType);
        analyticsService.generatePeriodAnalytics(startDate, endDate, periodType);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Page<Analytics>> getAllAnalytics(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching all analytics - page: {}, size: {}", page, size);
        Page<Analytics> analytics = analyticsService.getAnalytics(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(analytics);
    }
    
    @GetMapping("/categories")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<String>> getAvailableCategories() {
        log.info("Fetching available analytics categories");
        List<String> categories = analyticsService.getAvailableCategories();
        return ResponseEntity.ok(categories);
    }
    
    @GetMapping("/metric-types")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<Analytics.MetricType>> getAvailableMetricTypes() {
        log.info("Fetching available metric types");
        List<Analytics.MetricType> metricTypes = analyticsService.getAvailableMetricTypes();
        return ResponseEntity.ok(metricTypes);
    }
    
    @GetMapping("/period-types")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<Analytics.PeriodType>> getAvailablePeriodTypes() {
        log.info("Fetching available period types");
        List<Analytics.PeriodType> periodTypes = analyticsService.getAvailablePeriodTypes();
        return ResponseEntity.ok(periodTypes);
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getAnalyticsEnums() {
        return ResponseEntity.ok(Map.of(
                "metricTypes", Analytics.MetricType.values(),
                "periodTypes", Analytics.PeriodType.values()
        ));
    }
}