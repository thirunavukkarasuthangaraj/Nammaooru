package com.shopmanagement.service;

import com.shopmanagement.controller.EarningsController.*;
import com.shopmanagement.entity.DeliveryPartnerEarnings;
import com.shopmanagement.repository.DeliveryPartnerEarningsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Month;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PerformanceAnalyticsService {

    private final DeliveryPartnerEarningsRepository earningsRepository;

    /**
     * Get daily earnings breakdown
     */
    public List<DailyEarningsDTO> getDailyEarnings(String partnerId, LocalDate startDate, LocalDate endDate) {
        try {
            List<Object[]> dailyData = earningsRepository.getDailyEarningsSummary(partnerId, startDate, endDate);

            return dailyData.stream()
                .map(data -> {
                    LocalDate date = (LocalDate) data[0];
                    BigDecimal totalEarnings = (BigDecimal) data[1];
                    Long deliveryCount = (Long) data[2];

                    // Get detailed earnings for this date
                    List<DeliveryPartnerEarnings> dayEarnings = earningsRepository
                        .findByPartnerIdAndDateRange(partnerId, date, date);

                    BigDecimal commissionAmount = dayEarnings.stream()
                        .map(DeliveryPartnerEarnings::getCommissionAmount)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);

                    BigDecimal bonusAmount = dayEarnings.stream()
                        .map(e -> e.getBonusAmount() != null ? e.getBonusAmount() : BigDecimal.ZERO)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);

                    BigDecimal avgEarningPerDelivery = deliveryCount > 0
                        ? totalEarnings.divide(BigDecimal.valueOf(deliveryCount), 2, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;

                    return DailyEarningsDTO.builder()
                        .date(date)
                        .totalEarnings(totalEarnings)
                        .commissionAmount(commissionAmount)
                        .bonusAmount(bonusAmount)
                        .deliveryCount(deliveryCount.intValue())
                        .avgEarningPerDelivery(avgEarningPerDelivery)
                        .build();
                })
                .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error getting daily earnings for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get daily earnings: " + e.getMessage(), e);
        }
    }

    /**
     * Get weekly earnings breakdown
     */
    public List<WeeklyEarningsDTO> getWeeklyEarnings(String partnerId, LocalDate startDate, LocalDate endDate) {
        try {
            List<Object[]> weeklyData = earningsRepository.getWeeklyEarningsSummary(partnerId, startDate, endDate);

            return weeklyData.stream()
                .map(data -> {
                    Integer year = (Integer) data[0];
                    Integer week = (Integer) data[1];
                    BigDecimal totalEarnings = (BigDecimal) data[2];
                    Long deliveryCount = (Long) data[3];

                    // Calculate week start date
                    LocalDate weekStartDate = calculateWeekStartDate(year, week);

                    BigDecimal avgEarningPerDelivery = deliveryCount > 0
                        ? totalEarnings.divide(BigDecimal.valueOf(deliveryCount), 2, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;

                    return WeeklyEarningsDTO.builder()
                        .year(year)
                        .week(week)
                        .weekStartDate(weekStartDate)
                        .totalEarnings(totalEarnings)
                        .deliveryCount(deliveryCount.intValue())
                        .avgEarningPerDelivery(avgEarningPerDelivery)
                        .build();
                })
                .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error getting weekly earnings for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get weekly earnings: " + e.getMessage(), e);
        }
    }

    /**
     * Get monthly earnings breakdown
     */
    public List<MonthlyEarningsDTO> getMonthlyEarnings(String partnerId, LocalDate startDate, LocalDate endDate) {
        try {
            List<Object[]> monthlyData = earningsRepository.getMonthlyEarningsSummary(partnerId, startDate, endDate);

            return monthlyData.stream()
                .map(data -> {
                    Integer year = (Integer) data[0];
                    Integer month = (Integer) data[1];
                    BigDecimal totalEarnings = (BigDecimal) data[2];
                    BigDecimal commissionAmount = (BigDecimal) data[3];
                    BigDecimal bonusAmount = (BigDecimal) data[4];
                    BigDecimal penaltyAmount = (BigDecimal) data[5];
                    Long deliveryCount = (Long) data[6];

                    BigDecimal avgEarningPerDelivery = deliveryCount > 0
                        ? totalEarnings.divide(BigDecimal.valueOf(deliveryCount), 2, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;

                    String monthName = Month.of(month).name();

                    return MonthlyEarningsDTO.builder()
                        .year(year)
                        .month(month)
                        .monthName(monthName)
                        .totalEarnings(totalEarnings)
                        .commissionAmount(commissionAmount)
                        .bonusAmount(bonusAmount)
                        .penaltyAmount(penaltyAmount)
                        .deliveryCount(deliveryCount.intValue())
                        .avgEarningPerDelivery(avgEarningPerDelivery)
                        .build();
                })
                .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error getting monthly earnings for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get monthly earnings: " + e.getMessage(), e);
        }
    }

    /**
     * Get pending payments details
     */
    public Map<String, Object> getPendingPayments(String partnerId) {
        try {
            List<DeliveryPartnerEarnings> pendingEarnings = earningsRepository.getPendingPayments(partnerId);
            BigDecimal totalPendingAmount = earningsRepository.getTotalPendingAmount(partnerId);

            Map<String, Object> result = new HashMap<>();
            result.put("totalPendingAmount", totalPendingAmount);
            result.put("pendingDeliveryCount", pendingEarnings.size());
            result.put("pendingEarnings", pendingEarnings);

            // Group by date for better display
            Map<LocalDate, List<DeliveryPartnerEarnings>> groupedByDate = pendingEarnings.stream()
                .collect(Collectors.groupingBy(DeliveryPartnerEarnings::getEarningDate));

            result.put("pendingByDate", groupedByDate);

            return result;

        } catch (Exception e) {
            log.error("Error getting pending payments for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get pending payments: " + e.getMessage(), e);
        }
    }

    /**
     * Get comprehensive earnings statistics for dashboard
     */
    public EarningsStatisticsDTO getEarningsStatistics(String partnerId) {
        try {
            LocalDate weekStart = LocalDate.now().minusDays(6); // Last 7 days

            List<Object[]> statsData = earningsRepository.getEarningsStatistics(partnerId, weekStart);

            if (statsData.isEmpty()) {
                return EarningsStatisticsDTO.builder()
                    .todayEarnings(BigDecimal.ZERO)
                    .weekEarnings(BigDecimal.ZERO)
                    .monthEarnings(BigDecimal.ZERO)
                    .totalEarnings(BigDecimal.ZERO)
                    .pendingAmount(BigDecimal.ZERO)
                    .totalDeliveries(0L)
                    .avgEarningPerDelivery(BigDecimal.ZERO)
                    .avgCustomerRating(BigDecimal.ZERO)
                    .build();
            }

            Object[] stats = statsData.get(0);
            BigDecimal todayEarnings = (BigDecimal) stats[0];
            BigDecimal weekEarnings = (BigDecimal) stats[1];
            BigDecimal monthEarnings = (BigDecimal) stats[2];
            BigDecimal totalEarnings = (BigDecimal) stats[3];
            Long totalDeliveries = (Long) stats[4];

            // Get pending amount and performance metrics separately
            BigDecimal pendingAmount = earningsRepository.getTotalPendingAmount(partnerId);

            BigDecimal avgEarningPerDelivery = totalDeliveries > 0
                ? totalEarnings.divide(BigDecimal.valueOf(totalDeliveries), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

            // Get average customer rating
            List<Object[]> performanceData = earningsRepository.getPerformanceMetrics(
                partnerId, LocalDate.now().minusMonths(3), LocalDate.now());

            BigDecimal avgCustomerRating = BigDecimal.ZERO;
            if (!performanceData.isEmpty() && performanceData.get(0)[0] != null) {
                Double avgRating = (Double) performanceData.get(0)[0];
                avgCustomerRating = BigDecimal.valueOf(avgRating).setScale(2, RoundingMode.HALF_UP);
            }

            return EarningsStatisticsDTO.builder()
                .todayEarnings(todayEarnings)
                .weekEarnings(weekEarnings)
                .monthEarnings(monthEarnings)
                .totalEarnings(totalEarnings)
                .pendingAmount(pendingAmount)
                .totalDeliveries(totalDeliveries)
                .avgEarningPerDelivery(avgEarningPerDelivery)
                .avgCustomerRating(avgCustomerRating)
                .build();

        } catch (Exception e) {
            log.error("Error getting earnings statistics for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get earnings statistics: " + e.getMessage(), e);
        }
    }

    /**
     * Get performance analytics for detailed insights
     */
    public Map<String, Object> getPerformanceAnalytics(String partnerId, LocalDate startDate, LocalDate endDate) {
        try {
            List<Object[]> performanceData = earningsRepository.getPerformanceMetrics(partnerId, startDate, endDate);

            Map<String, Object> analytics = new HashMap<>();

            if (!performanceData.isEmpty()) {
                Object[] metrics = performanceData.get(0);
                Double avgRating = (Double) metrics[0];
                Double avgDeliveryTime = (Double) metrics[1];
                Double avgDistance = (Double) metrics[2];
                Long totalDeliveries = (Long) metrics[3];

                analytics.put("avgCustomerRating", avgRating != null ?
                    BigDecimal.valueOf(avgRating).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO);
                analytics.put("avgDeliveryTimeMinutes", avgDeliveryTime != null ?
                    BigDecimal.valueOf(avgDeliveryTime).setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO);
                analytics.put("avgDistanceKm", avgDistance != null ?
                    BigDecimal.valueOf(avgDistance).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO);
                analytics.put("totalDeliveries", totalDeliveries);

                // Calculate performance score (0-100)
                Double performanceScore = calculatePerformanceScore(avgRating, avgDeliveryTime, totalDeliveries);
                analytics.put("performanceScore", BigDecimal.valueOf(performanceScore).setScale(1, RoundingMode.HALF_UP));

                // Get achievement badges
                List<String> badges = calculateAchievementBadges(avgRating, avgDeliveryTime, totalDeliveries);
                analytics.put("achievementBadges", badges);
            } else {
                analytics.put("avgCustomerRating", BigDecimal.ZERO);
                analytics.put("avgDeliveryTimeMinutes", BigDecimal.ZERO);
                analytics.put("avgDistanceKm", BigDecimal.ZERO);
                analytics.put("totalDeliveries", 0L);
                analytics.put("performanceScore", BigDecimal.ZERO);
                analytics.put("achievementBadges", Collections.emptyList());
            }

            return analytics;

        } catch (Exception e) {
            log.error("Error getting performance analytics for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get performance analytics: " + e.getMessage(), e);
        }
    }

    /**
     * Calculate week start date from year and week number
     */
    private LocalDate calculateWeekStartDate(Integer year, Integer week) {
        WeekFields weekFields = WeekFields.of(Locale.getDefault());
        return LocalDate.of(year, 1, 1)
            .with(weekFields.weekOfYear(), week)
            .with(weekFields.dayOfWeek(), 1);
    }

    /**
     * Calculate performance score based on various metrics
     */
    private Double calculatePerformanceScore(Double avgRating, Double avgDeliveryTime, Long totalDeliveries) {
        double score = 0.0;

        // Rating component (40% weight)
        if (avgRating != null) {
            score += (avgRating / 5.0) * 40.0;
        }

        // Speed component (30% weight) - faster delivery gets higher score
        if (avgDeliveryTime != null) {
            double speedScore = Math.max(0, (60.0 - avgDeliveryTime) / 60.0); // Assuming 60 min baseline
            score += speedScore * 30.0;
        }

        // Volume component (30% weight) - more deliveries get higher score
        if (totalDeliveries != null) {
            double volumeScore = Math.min(1.0, totalDeliveries / 100.0); // 100 deliveries = full score
            score += volumeScore * 30.0;
        }

        return Math.min(100.0, Math.max(0.0, score));
    }

    /**
     * Calculate achievement badges based on performance
     */
    private List<String> calculateAchievementBadges(Double avgRating, Double avgDeliveryTime, Long totalDeliveries) {
        List<String> badges = new ArrayList<>();

        if (avgRating != null && avgRating >= 4.8) {
            badges.add("⭐ Top Rated");
        }

        if (avgDeliveryTime != null && avgDeliveryTime <= 25) {
            badges.add("⚡ Speed Demon");
        }

        if (totalDeliveries != null) {
            if (totalDeliveries >= 500) {
                badges.add("🏆 Elite Delivery Partner");
            } else if (totalDeliveries >= 100) {
                badges.add("🥉 Bronze Partner");
            } else if (totalDeliveries >= 50) {
                badges.add("🌟 Rising Star");
            }
        }

        if (avgRating != null && avgRating >= 4.5 && avgDeliveryTime != null && avgDeliveryTime <= 30) {
            badges.add("💎 Consistent Performer");
        }

        return badges;
    }
}