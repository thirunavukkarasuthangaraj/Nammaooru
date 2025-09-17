package com.shopmanagement.controller;

import com.shopmanagement.entity.DeliveryPartnerEarnings;
import com.shopmanagement.service.EarningsCalculationService;
import com.shopmanagement.service.PerformanceAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery-partners/{partnerId}/earnings")
@RequiredArgsConstructor
@Slf4j
public class EarningsController {

    private final EarningsCalculationService earningsCalculationService;
    private final PerformanceAnalyticsService performanceAnalyticsService;

    /**
     * Calculate earnings for a completed delivery
     */
    @PostMapping("/calculate")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> calculateEarnings(
            @PathVariable String partnerId,
            @RequestBody EarningsCalculationRequest request) {

        try {
            DeliveryPartnerEarnings earnings = earningsCalculationService.calculateEarnings(
                request.getOrderId(),
                partnerId,
                request.getPickupTime(),
                request.getDeliveryTime(),
                request.getDistance(),
                request.getCustomerRating()
            );

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Earnings calculated successfully");
            response.put("earnings", earnings);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error calculating earnings for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to calculate earnings: " + e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get earnings summary for date range
     */
    @GetMapping("/summary")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<EarningsCalculationService.EarningsSummaryDTO> getEarningsSummary(
            @PathVariable String partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        try {
            EarningsCalculationService.EarningsSummaryDTO summary =
                earningsCalculationService.getEarningsSummary(partnerId, startDate, endDate);

            return ResponseEntity.ok(summary);

        } catch (Exception e) {
            log.error("Error getting earnings summary for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get daily earnings breakdown
     */
    @GetMapping("/daily")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<List<DailyEarningsDTO>> getDailyEarnings(
            @PathVariable String partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        try {
            List<DailyEarningsDTO> dailyEarnings =
                performanceAnalyticsService.getDailyEarnings(partnerId, startDate, endDate);

            return ResponseEntity.ok(dailyEarnings);

        } catch (Exception e) {
            log.error("Error getting daily earnings for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get weekly earnings breakdown
     */
    @GetMapping("/weekly")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<List<WeeklyEarningsDTO>> getWeeklyEarnings(
            @PathVariable String partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        try {
            List<WeeklyEarningsDTO> weeklyEarnings =
                performanceAnalyticsService.getWeeklyEarnings(partnerId, startDate, endDate);

            return ResponseEntity.ok(weeklyEarnings);

        } catch (Exception e) {
            log.error("Error getting weekly earnings for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get monthly earnings breakdown
     */
    @GetMapping("/monthly")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<List<MonthlyEarningsDTO>> getMonthlyEarnings(
            @PathVariable String partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        try {
            List<MonthlyEarningsDTO> monthlyEarnings =
                performanceAnalyticsService.getMonthlyEarnings(partnerId, startDate, endDate);

            return ResponseEntity.ok(monthlyEarnings);

        } catch (Exception e) {
            log.error("Error getting monthly earnings for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get pending payments
     */
    @GetMapping("/pending")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getPendingPayments(@PathVariable String partnerId) {

        try {
            Map<String, Object> pendingData = performanceAnalyticsService.getPendingPayments(partnerId);
            return ResponseEntity.ok(pendingData);

        } catch (Exception e) {
            log.error("Error getting pending payments for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Get earnings statistics for dashboard
     */
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<EarningsStatisticsDTO> getEarningsStatistics(@PathVariable String partnerId) {

        try {
            EarningsStatisticsDTO statistics =
                performanceAnalyticsService.getEarningsStatistics(partnerId);

            return ResponseEntity.ok(statistics);

        } catch (Exception e) {
            log.error("Error getting earnings statistics for partner {}: {}", partnerId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Update earnings with manual adjustments
     */
    @PutMapping("/{earningsId}/adjust")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> adjustEarnings(
            @PathVariable String partnerId,
            @PathVariable Long earningsId,
            @RequestBody EarningsAdjustmentRequest request) {

        try {
            DeliveryPartnerEarnings updatedEarnings = earningsCalculationService.updateEarnings(
                earningsId,
                request.getBonusAdjustment(),
                request.getPenaltyAdjustment(),
                request.getReason()
            );

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Earnings adjusted successfully");
            response.put("earnings", updatedEarnings);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error adjusting earnings for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to adjust earnings: " + e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    // DTO Classes
    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class EarningsCalculationRequest {
        private Long orderId;
        private LocalDateTime pickupTime;
        private LocalDateTime deliveryTime;
        private BigDecimal distance;
        private BigDecimal customerRating;
    }

    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class EarningsAdjustmentRequest {
        private BigDecimal bonusAdjustment;
        private BigDecimal penaltyAdjustment;
        private String reason;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyEarningsDTO {
        private LocalDate date;
        private BigDecimal totalEarnings;
        private BigDecimal commissionAmount;
        private BigDecimal bonusAmount;
        private Integer deliveryCount;
        private BigDecimal avgEarningPerDelivery;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class WeeklyEarningsDTO {
        private Integer year;
        private Integer week;
        private LocalDate weekStartDate;
        private BigDecimal totalEarnings;
        private Integer deliveryCount;
        private BigDecimal avgEarningPerDelivery;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class MonthlyEarningsDTO {
        private Integer year;
        private Integer month;
        private String monthName;
        private BigDecimal totalEarnings;
        private BigDecimal commissionAmount;
        private BigDecimal bonusAmount;
        private BigDecimal penaltyAmount;
        private Integer deliveryCount;
        private BigDecimal avgEarningPerDelivery;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class EarningsStatisticsDTO {
        private BigDecimal todayEarnings;
        private BigDecimal weekEarnings;
        private BigDecimal monthEarnings;
        private BigDecimal totalEarnings;
        private BigDecimal pendingAmount;
        private Long totalDeliveries;
        private BigDecimal avgEarningPerDelivery;
        private BigDecimal avgCustomerRating;
    }
}