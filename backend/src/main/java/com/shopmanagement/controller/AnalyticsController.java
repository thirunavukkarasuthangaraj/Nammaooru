package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
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
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Slf4j
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @PostMapping("/dashboard")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<AnalyticsResponse.DashboardMetrics>> getDashboardMetrics(@Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching dashboard metrics for period: {} to {}", request.getStartDate(), request.getEndDate());
        AnalyticsResponse.DashboardMetrics metrics = analyticsService.getDashboardMetrics(request);
        return ResponseUtil.success(metrics, "Dashboard metrics retrieved successfully");
    }

    @PostMapping("/dashboard/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<AnalyticsResponse.DashboardMetrics>> getShopDashboardMetrics(
            @PathVariable Long shopId,
            @Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching shop dashboard metrics for shop: {} for period: {} to {}", shopId, request.getStartDate(), request.getEndDate());
        AnalyticsResponse.DashboardMetrics metrics = analyticsService.getShopDashboardMetrics(shopId, request);
        return ResponseUtil.success(metrics, "Shop dashboard metrics retrieved successfully");
    }

    @PostMapping("/customers")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<AnalyticsResponse.CustomerAnalytics>> getCustomerAnalytics(@Valid @RequestBody AnalyticsRequest request) {
        log.info("Fetching customer analytics for period: {} to {}", request.getStartDate(), request.getEndDate());
        AnalyticsResponse.CustomerAnalytics analytics = analyticsService.getCustomerAnalytics(request);
        return ResponseUtil.success(analytics, "Customer analytics retrieved successfully");
    }

    @PostMapping("/generate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> generateAnalytics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam Analytics.PeriodType periodType) {
        log.info("Generating analytics for period: {} to {} ({})", startDate, endDate, periodType);
        analyticsService.generatePeriodAnalytics(startDate, endDate, periodType);
        return ResponseUtil.success(null, "Analytics generated successfully");
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Page<Analytics>>> getAllAnalytics(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching all analytics - page: {}, size: {}", page, size);
        Page<Analytics> analytics = analyticsService.getAnalytics(page, size, sortBy, sortDirection);
        return ResponseUtil.success(analytics);
    }

    @GetMapping("/categories")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<String>>> getAvailableCategories() {
        log.info("Fetching available analytics categories");
        List<String> categories = analyticsService.getAvailableCategories();
        return ResponseUtil.success(categories);
    }

    @GetMapping("/metric-types")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<Analytics.MetricType>>> getAvailableMetricTypes() {
        log.info("Fetching available metric types");
        List<Analytics.MetricType> metricTypes = analyticsService.getAvailableMetricTypes();
        return ResponseUtil.success(metricTypes);
    }

    @GetMapping("/period-types")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<Analytics.PeriodType>>> getAvailablePeriodTypes() {
        log.info("Fetching available period types");
        List<Analytics.PeriodType> periodTypes = analyticsService.getAvailablePeriodTypes();
        return ResponseUtil.success(periodTypes);
    }

    @GetMapping("/enums")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAnalyticsEnums() {
        return ResponseUtil.success(Map.of(
                "metricTypes", Analytics.MetricType.values(),
                "periodTypes", Analytics.PeriodType.values()
        ));
    }
}
