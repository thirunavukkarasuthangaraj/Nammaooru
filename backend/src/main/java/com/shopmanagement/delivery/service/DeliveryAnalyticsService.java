package com.shopmanagement.delivery.service;

import com.shopmanagement.delivery.entity.*;
import com.shopmanagement.delivery.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeliveryAnalyticsService {

    private final OrderAssignmentRepository assignmentRepository;
    private final DeliveryPartnerRepository partnerRepository;
    private final PartnerEarningRepository earningRepository;
    private final DeliveryTrackingRepository trackingRepository;

    public Map<String, Object> getKeyMetrics(LocalDate startDate, LocalDate endDate) {
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);

        Map<String, Object> metrics = new HashMap<>();
        
        // Total deliveries
        List<OrderAssignment> assignments = assignmentRepository
                .findByDateRangeAndStatus(startDateTime, endDateTime, OrderAssignment.AssignmentStatus.DELIVERED);
        metrics.put("totalDeliveries", assignments.size());
        
        // Success rate
        long totalAssignments = assignmentRepository.count();
        double successRate = totalAssignments > 0 ? 
                (assignments.size() * 100.0 / totalAssignments) : 0;
        metrics.put("successRate", Math.round(successRate * 10) / 10.0);
        
        // Average delivery time
        double avgDeliveryTime = calculateAverageDeliveryTime(assignments);
        metrics.put("avgDeliveryTime", Math.round(avgDeliveryTime));
        
        // Total revenue
        BigDecimal totalRevenue = calculateTotalRevenue(startDate, endDate);
        metrics.put("totalRevenue", totalRevenue.doubleValue());
        
        // Active partners
        long activePartners = partnerRepository.countByStatus(DeliveryPartner.PartnerStatus.ACTIVE);
        metrics.put("activePartners", activePartners);
        
        // Average rating
        Double avgRating = calculateAverageRating();
        metrics.put("avgRating", avgRating != null ? Math.round(avgRating * 10) / 10.0 : 0);
        
        // On-time delivery rate
        double onTimeRate = calculateOnTimeDeliveryRate(assignments);
        metrics.put("onTimeDeliveryRate", Math.round(onTimeRate * 10) / 10.0);
        
        // Total distance
        double totalDistance = calculateTotalDistance(assignments);
        metrics.put("totalDistance", Math.round(totalDistance * 10) / 10.0);
        
        return metrics;
    }

    public Map<String, Object> getDeliveryTrends(LocalDate startDate, LocalDate endDate, String groupBy) {
        Map<String, Object> trends = new HashMap<>();
        List<String> labels = new ArrayList<>();
        List<Integer> values = new ArrayList<>();
        
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            LocalDateTime dayStart = current.atStartOfDay();
            LocalDateTime dayEnd = current.atTime(23, 59, 59);
            
            List<OrderAssignment> dayAssignments = assignmentRepository
                    .findByDateRangeAndStatus(dayStart, dayEnd, OrderAssignment.AssignmentStatus.DELIVERED);
            
            labels.add(current.toString());
            values.add(dayAssignments.size());
            
            current = current.plusDays(1);
        }
        
        trends.put("labels", labels);
        trends.put("values", values);
        
        return trends;
    }

    public List<Map<String, Object>> getTopPerformingPartners(int limit) {
        List<DeliveryPartner> topPartners = partnerRepository.findTopRatedPartners(BigDecimal.valueOf(4.0));
        
        return topPartners.stream()
                .limit(limit)
                .map(partner -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("partnerId", partner.getId());
                    data.put("partnerName", partner.getFullName());
                    data.put("deliveries", partner.getTotalDeliveries());
                    data.put("successRate", partner.getSuccessRate().doubleValue());
                    data.put("avgTime", calculatePartnerAvgDeliveryTime(partner.getId()));
                    data.put("rating", partner.getRating().doubleValue());
                    data.put("earnings", partner.getTotalEarnings().doubleValue());
                    return data;
                })
                .collect(Collectors.toList());
    }

    public Map<String, Object> getPartnerPerformance(Long partnerId, LocalDate startDate, LocalDate endDate) {
        DeliveryPartner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("Partner not found"));
        
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);
        
        List<OrderAssignment> assignments = assignmentRepository
                .findByPartnerAndDateRange(partnerId, startDateTime, endDateTime);
        
        Map<String, Object> performance = new HashMap<>();
        performance.put("partnerId", partner.getId());
        performance.put("partnerName", partner.getFullName());
        performance.put("totalDeliveries", assignments.size());
        performance.put("successfulDeliveries", 
                assignments.stream().filter(a -> a.getStatus() == OrderAssignment.AssignmentStatus.DELIVERED).count());
        performance.put("avgDeliveryTime", calculateAverageDeliveryTime(assignments));
        performance.put("totalEarnings", 
                earningRepository.getTotalEarningsByPartnerAndDateRange(partnerId, startDate, endDate));
        performance.put("rating", partner.getRating());
        
        return performance;
    }

    public List<Map<String, Object>> getZonePerformance() {
        // Mock implementation - replace with actual zone data
        List<Map<String, Object>> zones = new ArrayList<>();
        
        Map<String, Object> zone1 = new HashMap<>();
        zone1.put("zoneId", 1);
        zone1.put("zoneName", "Central Zone");
        zone1.put("totalOrders", 245);
        zone1.put("avgDeliveryTime", 35);
        zone1.put("successRate", 96.5);
        zone1.put("revenue", 45600.00);
        zones.add(zone1);
        
        Map<String, Object> zone2 = new HashMap<>();
        zone2.put("zoneId", 2);
        zone2.put("zoneName", "North Zone");
        zone2.put("totalOrders", 180);
        zone2.put("avgDeliveryTime", 42);
        zone2.put("successRate", 94.2);
        zone2.put("revenue", 38500.00);
        zones.add(zone2);
        
        return zones;
    }

    public Map<String, Object> getZoneDetails(Long zoneId, LocalDate startDate, LocalDate endDate) {
        Map<String, Object> details = new HashMap<>();
        details.put("zoneId", zoneId);
        details.put("zoneName", "Zone " + zoneId);
        details.put("totalOrders", 150);
        details.put("avgDeliveryTime", 38);
        details.put("successRate", 95.0);
        details.put("revenue", 35000.00);
        return details;
    }

    public Map<String, Integer> getStatusDistribution(LocalDate startDate, LocalDate endDate) {
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);
        
        Map<String, Integer> distribution = new HashMap<>();
        
        distribution.put("delivered", 
                assignmentRepository.findByDateRangeAndStatus(startDateTime, endDateTime, 
                        OrderAssignment.AssignmentStatus.DELIVERED).size());
        distribution.put("inTransit", 
                assignmentRepository.findByDateRangeAndStatus(startDateTime, endDateTime, 
                        OrderAssignment.AssignmentStatus.IN_TRANSIT).size());
        distribution.put("failed", 
                assignmentRepository.findByDateRangeAndStatus(startDateTime, endDateTime, 
                        OrderAssignment.AssignmentStatus.FAILED).size());
        distribution.put("cancelled", 
                assignmentRepository.findByDateRangeAndStatus(startDateTime, endDateTime, 
                        OrderAssignment.AssignmentStatus.CANCELLED).size());
        
        return distribution;
    }

    public Map<String, Object> getPeakHoursAnalysis() {
        Map<String, Object> peakHours = new HashMap<>();
        List<String> hours = new ArrayList<>();
        List<Integer> orders = new ArrayList<>();
        
        // Analyze orders by hour for the last 30 days
        for (int hour = 0; hour < 24; hour++) {
            hours.add(String.format("%02d:00", hour));
            // Mock data - replace with actual query
            orders.add((int)(Math.random() * 50 + 10));
        }
        
        peakHours.put("hours", hours);
        peakHours.put("orders", orders);
        
        return peakHours;
    }

    public Map<String, Object> getRevenueAnalytics(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> revenue = new HashMap<>();
        List<String> labels = new ArrayList<>();
        List<Double> revenueData = new ArrayList<>();
        List<Double> commissionData = new ArrayList<>();
        
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            labels.add(current.toString());
            
            BigDecimal dayRevenue = earningRepository.getTotalEarningsByPartnerAndDateRange(
                    null, current, current);
            revenueData.add(dayRevenue != null ? dayRevenue.doubleValue() : 0.0);
            
            // Commission is typically 20% of revenue
            commissionData.add(dayRevenue != null ? 
                    dayRevenue.multiply(BigDecimal.valueOf(0.2)).doubleValue() : 0.0);
            
            current = current.plusDays(1);
        }
        
        revenue.put("labels", labels);
        revenue.put("revenue", revenueData);
        revenue.put("commission", commissionData);
        
        return revenue;
    }

    public Map<String, Object> getCustomerSatisfaction() {
        Map<String, Object> satisfaction = new HashMap<>();
        
        Double avgRating = assignmentRepository.getAverageRatingForPartner(null);
        satisfaction.put("avgRating", avgRating != null ? Math.round(avgRating * 10) / 10.0 : 0);
        satisfaction.put("totalReviews", 523); // Mock data
        
        Map<Integer, Integer> distribution = new HashMap<>();
        distribution.put(5, 320);
        distribution.put(4, 125);
        distribution.put(3, 45);
        distribution.put(2, 20);
        distribution.put(1, 13);
        satisfaction.put("distribution", distribution);
        
        return satisfaction;
    }

    public Map<String, Object> getVehicleTypePerformance() {
        Map<String, Object> vehiclePerformance = new HashMap<>();
        
        // Mock data - replace with actual queries
        vehiclePerformance.put("BIKE", Map.of("count", 450, "avgTime", 32, "successRate", 96.5));
        vehiclePerformance.put("SCOOTER", Map.of("count", 280, "avgTime", 35, "successRate", 94.8));
        vehiclePerformance.put("BICYCLE", Map.of("count", 120, "avgTime", 45, "successRate", 92.3));
        vehiclePerformance.put("CAR", Map.of("count", 80, "avgTime", 28, "successRate", 97.2));
        vehiclePerformance.put("AUTO", Map.of("count", 150, "avgTime", 30, "successRate", 95.6));
        
        return vehiclePerformance;
    }

    public Map<String, Object> getDeliveryTimeAnalysis(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> analysis = new HashMap<>();
        
        analysis.put("avgDeliveryTime", 35.5);
        analysis.put("minDeliveryTime", 15);
        analysis.put("maxDeliveryTime", 120);
        analysis.put("medianDeliveryTime", 32);
        
        return analysis;
    }

    public Map<String, Object> getFailedDeliveryAnalysis(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> analysis = new HashMap<>();
        
        Map<String, Integer> reasons = new HashMap<>();
        reasons.put("Customer Unavailable", 45);
        reasons.put("Wrong Address", 23);
        reasons.put("Partner Issue", 12);
        reasons.put("Weather", 8);
        reasons.put("Other", 15);
        
        analysis.put("totalFailed", 103);
        analysis.put("reasons", reasons);
        analysis.put("failureRate", 2.3);
        
        return analysis;
    }

    public List<Map<String, Object>> getAllZones() {
        // Return all zones for filter
        return getZonePerformance();
    }

    public List<Map<String, Object>> getAllPartners() {
        return partnerRepository.findAll().stream()
                .map(partner -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("id", partner.getId());
                    data.put("name", partner.getFullName());
                    data.put("partnerId", partner.getPartnerId());
                    return data;
                })
                .collect(Collectors.toList());
    }

    public byte[] generateReport(String format, LocalDate startDate, LocalDate endDate) {
        // Mock implementation - replace with actual report generation
        String reportContent = String.format("Delivery Analytics Report\nPeriod: %s to %s\n", 
                startDate, endDate);
        return reportContent.getBytes();
    }

    public Map<String, Object> getDashboardStats() {
        Map<String, Object> dashboard = new HashMap<>();
        
        dashboard.put("onlinePartners", partnerRepository.findAvailablePartners().size());
        dashboard.put("activeDeliveries", 
                assignmentRepository.findByStatus(OrderAssignment.AssignmentStatus.IN_TRANSIT).size());
        dashboard.put("pendingAssignments", 
                assignmentRepository.findByStatus(OrderAssignment.AssignmentStatus.ASSIGNED).size());
        dashboard.put("todayDeliveries", 
                assignmentRepository.findByDateRangeAndStatus(
                        LocalDate.now().atStartOfDay(), 
                        LocalDate.now().atTime(23, 59, 59),
                        OrderAssignment.AssignmentStatus.DELIVERED).size());
        
        return dashboard;
    }

    public Map<String, Object> getDemandForecast(int days) {
        Map<String, Object> forecast = new HashMap<>();
        List<String> dates = new ArrayList<>();
        List<Integer> predicted = new ArrayList<>();
        
        LocalDate current = LocalDate.now();
        for (int i = 0; i < days; i++) {
            dates.add(current.plusDays(i).toString());
            // Mock prediction - replace with ML model
            predicted.add((int)(Math.random() * 50 + 100));
        }
        
        forecast.put("dates", dates);
        forecast.put("predicted", predicted);
        
        return forecast;
    }

    public Map<String, Object> getPartnerUtilization() {
        Map<String, Object> utilization = new HashMap<>();
        
        long totalPartners = partnerRepository.count();
        long activePartners = partnerRepository.countByStatus(DeliveryPartner.PartnerStatus.ACTIVE);
        long onlinePartners = partnerRepository.findAvailablePartners().size();
        
        utilization.put("totalPartners", totalPartners);
        utilization.put("activePartners", activePartners);
        utilization.put("onlinePartners", onlinePartners);
        utilization.put("utilizationRate", 
                totalPartners > 0 ? (onlinePartners * 100.0 / totalPartners) : 0);
        
        return utilization;
    }

    public Map<String, Object> getRouteEfficiency(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> efficiency = new HashMap<>();
        
        efficiency.put("avgDistancePerDelivery", 5.2);
        efficiency.put("avgFuelCost", 45.5);
        efficiency.put("optimalRoutePercentage", 78.5);
        efficiency.put("avgDeviationFromOptimal", 1.2);
        
        return efficiency;
    }

    // Helper methods
    
    private double calculateAverageDeliveryTime(List<OrderAssignment> assignments) {
        if (assignments.isEmpty()) return 0;
        
        double totalMinutes = assignments.stream()
                .filter(a -> a.getDeliveryTime() != null && a.getAcceptedAt() != null)
                .mapToLong(a -> ChronoUnit.MINUTES.between(a.getAcceptedAt(), a.getDeliveryTime()))
                .average()
                .orElse(0);
        
        return totalMinutes;
    }

    private BigDecimal calculateTotalRevenue(LocalDate startDate, LocalDate endDate) {
        List<PartnerEarning> earnings = earningRepository.findPendingPayments(endDate);
        return earnings.stream()
                .map(PartnerEarning::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private Double calculateAverageRating() {
        return assignmentRepository.getAverageRatingForPartner(null);
    }

    private double calculateOnTimeDeliveryRate(List<OrderAssignment> assignments) {
        if (assignments.isEmpty()) return 0;
        
        long onTimeDeliveries = assignments.stream()
                .filter(a -> a.getDeliveryTime() != null && 
                        a.getOrder().getEstimatedDeliveryTime() != null &&
                        !a.getDeliveryTime().isAfter(a.getOrder().getEstimatedDeliveryTime().plusMinutes(15)))
                .count();
        
        return (onTimeDeliveries * 100.0) / assignments.size();
    }

    private double calculateTotalDistance(List<OrderAssignment> assignments) {
        // Mock calculation - replace with actual distance calculation
        return assignments.size() * 5.5; // Average 5.5 km per delivery
    }

    private double calculatePartnerAvgDeliveryTime(Long partnerId) {
        List<OrderAssignment> assignments = assignmentRepository.findByDeliveryPartnerId(partnerId);
        return calculateAverageDeliveryTime(assignments);
    }
}