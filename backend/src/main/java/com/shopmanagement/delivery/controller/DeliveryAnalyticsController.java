package com.shopmanagement.delivery.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.delivery.service.DeliveryAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery/analytics")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
public class DeliveryAnalyticsController {

    private final DeliveryAnalyticsService analyticsService;

    @GetMapping("/metrics")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getKeyMetrics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> metrics = analyticsService.getKeyMetrics(startDate, endDate);
        return ResponseUtil.success(metrics);
    }

    @GetMapping("/trends")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDeliveryTrends(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "day") String groupBy) {
        
        Map<String, Object> trends = analyticsService.getDeliveryTrends(startDate, endDate, groupBy);
        return ResponseUtil.success(trends);
    }

    @GetMapping("/partners/top")
    public ResponseEntity<ApiResponse<Object>> getTopPartners(
            @RequestParam(defaultValue = "10") int limit) {
        
        return ResponseUtil.success(analyticsService.getTopPerformingPartners(limit));
    }

    @GetMapping("/partners/{partnerId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPartnerPerformance(
            @PathVariable Long partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> performance = analyticsService.getPartnerPerformance(partnerId, startDate, endDate);
        return ResponseUtil.success(performance);
    }

    @GetMapping("/zones")
    public ResponseEntity<ApiResponse<Object>> getZonePerformance() {
        return ResponseUtil.success(analyticsService.getZonePerformance());
    }

    @GetMapping("/zones/{zoneId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getZoneDetails(
            @PathVariable Long zoneId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> zoneDetails = analyticsService.getZoneDetails(zoneId, startDate, endDate);
        return ResponseUtil.success(zoneDetails);
    }

    @GetMapping("/status-distribution")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> getStatusDistribution(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Integer> distribution = analyticsService.getStatusDistribution(startDate, endDate);
        return ResponseUtil.success(distribution);
    }

    @GetMapping("/peak-hours")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPeakHours() {
        Map<String, Object> peakHours = analyticsService.getPeakHoursAnalysis();
        return ResponseUtil.success(peakHours);
    }

    @GetMapping("/revenue")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRevenueAnalytics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> revenue = analyticsService.getRevenueAnalytics(startDate, endDate);
        return ResponseUtil.success(revenue);
    }

    @GetMapping("/customer-satisfaction")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCustomerSatisfaction() {
        Map<String, Object> satisfaction = analyticsService.getCustomerSatisfaction();
        return ResponseUtil.success(satisfaction);
    }

    @GetMapping("/vehicle-types")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getVehicleTypePerformance() {
        Map<String, Object> vehiclePerformance = analyticsService.getVehicleTypePerformance();
        return ResponseUtil.success(vehiclePerformance);
    }

    @GetMapping("/delivery-times")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDeliveryTimeAnalysis(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> deliveryTimes = analyticsService.getDeliveryTimeAnalysis(startDate, endDate);
        return ResponseUtil.success(deliveryTimes);
    }

    @GetMapping("/failed-deliveries")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFailedDeliveryAnalysis(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> failedAnalysis = analyticsService.getFailedDeliveryAnalysis(startDate, endDate);
        return ResponseUtil.success(failedAnalysis);
    }

    @GetMapping("/filters/zones")
    public ResponseEntity<ApiResponse<Object>> getZonesFilter() {
        return ResponseUtil.success(analyticsService.getAllZones());
    }

    @GetMapping("/filters/partners")
    public ResponseEntity<ApiResponse<Object>> getPartnersFilter() {
        return ResponseUtil.success(analyticsService.getAllPartners());
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportReport(
            @RequestParam String format,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        try {
            byte[] reportData = analyticsService.generateReport(format, startDate, endDate);
            
            HttpHeaders headers = new HttpHeaders();
            String filename = String.format("delivery-analytics-%s.%s", 
                LocalDate.now().toString(), format.toLowerCase());
            
            if ("pdf".equalsIgnoreCase(format)) {
                headers.setContentType(MediaType.APPLICATION_PDF);
            } else if ("excel".equalsIgnoreCase(format) || "xlsx".equalsIgnoreCase(format)) {
                headers.setContentType(MediaType.parseMediaType("application/vnd.ms-excel"));
            } else {
                headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            }
            
            headers.setContentDispositionFormData("attachment", filename);
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(reportData);
                    
        } catch (Exception e) {
            log.error("Error generating report: {}", e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboardStats() {
        Map<String, Object> dashboard = analyticsService.getDashboardStats();
        return ResponseUtil.success(dashboard);
    }

    @GetMapping("/forecast")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDemandForecast(
            @RequestParam(defaultValue = "7") int days) {
        
        Map<String, Object> forecast = analyticsService.getDemandForecast(days);
        return ResponseUtil.success(forecast);
    }

    @GetMapping("/partner-utilization")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPartnerUtilization() {
        Map<String, Object> utilization = analyticsService.getPartnerUtilization();
        return ResponseUtil.success(utilization);
    }

    @GetMapping("/route-efficiency")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRouteEfficiency(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        Map<String, Object> efficiency = analyticsService.getRouteEfficiency(startDate, endDate);
        return ResponseUtil.success(efficiency);
    }
}