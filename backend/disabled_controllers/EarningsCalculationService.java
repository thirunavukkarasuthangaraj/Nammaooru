package com.shopmanagement.service;

import com.shopmanagement.entity.*;
import com.shopmanagement.repository.DeliveryPartnerEarningsRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class EarningsCalculationService {

    private final DeliveryPartnerEarningsRepository earningsRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;

    @Value("${delivery.commission.default-rate:0.8000}")
    private BigDecimal defaultCommissionRate;

    @Value("${delivery.commission.peak-hours-bonus:0.1000}")
    private BigDecimal peakHoursBonus;

    @Value("${delivery.commission.weekend-bonus:0.0500}")
    private BigDecimal weekendBonus;

    @Value("${delivery.commission.distance-bonus-threshold:10.0}")
    private BigDecimal distanceBonusThreshold;

    @Value("${delivery.commission.distance-bonus-rate:0.0500}")
    private BigDecimal distanceBonusRate;

    /**
     * Calculate and record earnings for a completed delivery
     */
    @Transactional
    public DeliveryPartnerEarnings calculateEarnings(Long orderId, String deliveryPartnerId,
                                                   LocalDateTime pickupTime, LocalDateTime deliveryTime,
                                                   BigDecimal distance, BigDecimal customerRating) {
        try {
            // Get order details
            Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

            // Get delivery partner (User with DELIVERY_PARTNER role)
            User partner = userRepository.findById(Long.valueOf(deliveryPartnerId))
                .orElseThrow(() -> new RuntimeException("Delivery partner not found: " + deliveryPartnerId));

            // Check if earnings already exist for this order
            Optional<DeliveryPartnerEarnings> existingEarnings = earningsRepository.findByOrderId(orderId);
            if (existingEarnings.isPresent()) {
                log.warn("Earnings already calculated for order: {}", orderId);
                return existingEarnings.get();
            }

            // Calculate delivery time in minutes
            Integer deliveryTimeMinutes = null;
            if (pickupTime != null && deliveryTime != null) {
                deliveryTimeMinutes = (int) ChronoUnit.MINUTES.between(pickupTime, deliveryTime);
            }

            // Calculate commission rate with bonuses
            BigDecimal commissionRate = calculateCommissionRate(deliveryTime, distance);

            // Calculate bonus amounts
            BigDecimal bonusAmount = calculateBonusAmount(order.getDeliveryFee(), deliveryTime,
                                                        distance, deliveryTimeMinutes, customerRating);

            // Calculate penalty (if any)
            BigDecimal penaltyAmount = calculatePenaltyAmount(deliveryTimeMinutes, customerRating);

            // Create earnings record
            DeliveryPartnerEarnings earnings = DeliveryPartnerEarnings.builder()
                .deliveryPartner(partner)
                .order(order)
                .earningDate(LocalDate.now())
                .deliveryFee(order.getDeliveryFee())
                .commissionRate(commissionRate)
                .bonusAmount(bonusAmount)
                .penaltyAmount(penaltyAmount)
                .deliveryTimeMinutes(deliveryTimeMinutes)
                .distanceKm(distance)
                .customerRating(customerRating)
                .paymentStatus(DeliveryPartnerEarnings.PaymentStatus.PENDING)
                .createdBy("earnings-system")
                .build();

            // Calculate all earning amounts
            earnings.calculateEarnings();

            // Save and return
            DeliveryPartnerEarnings savedEarnings = earningsRepository.save(earnings);

            log.info("Earnings calculated for order {}: Partner {} earned {} (Commission: {}, Bonus: {}, Penalty: {})",
                orderId, deliveryPartnerId, savedEarnings.getFinalEarning(),
                savedEarnings.getCommissionAmount(), savedEarnings.getBonusAmount(), savedEarnings.getPenaltyAmount());

            return savedEarnings;

        } catch (Exception e) {
            log.error("Error calculating earnings for order {}: {}", orderId, e.getMessage(), e);
            throw new RuntimeException("Failed to calculate earnings: " + e.getMessage(), e);
        }
    }

    /**
     * Calculate commission rate with time-based bonuses
     */
    private BigDecimal calculateCommissionRate(LocalDateTime deliveryTime, BigDecimal distance) {
        BigDecimal rate = defaultCommissionRate;

        if (deliveryTime != null) {
            // Peak hours bonus (7-9 AM, 12-2 PM, 6-9 PM)
            LocalTime time = deliveryTime.toLocalTime();
            if (isPeakHours(time)) {
                rate = rate.add(peakHoursBonus);
            }

            // Weekend bonus
            if (isWeekend(deliveryTime)) {
                rate = rate.add(weekendBonus);
            }
        }

        // Distance bonus for long deliveries
        if (distance != null && distance.compareTo(distanceBonusThreshold) > 0) {
            rate = rate.add(distanceBonusRate);
        }

        // Cap at 100%
        return rate.min(BigDecimal.ONE);
    }

    /**
     * Calculate bonus amount based on performance
     */
    private BigDecimal calculateBonusAmount(BigDecimal deliveryFee, LocalDateTime deliveryTime,
                                          BigDecimal distance, Integer deliveryTimeMinutes, BigDecimal customerRating) {
        BigDecimal bonus = BigDecimal.ZERO;

        // Fast delivery bonus (under 30 minutes)
        if (deliveryTimeMinutes != null && deliveryTimeMinutes <= 30) {
            bonus = bonus.add(deliveryFee.multiply(new BigDecimal("0.05"))); // 5% bonus
        }

        // High rating bonus (4.5+ stars)
        if (customerRating != null && customerRating.compareTo(new BigDecimal("4.5")) >= 0) {
            bonus = bonus.add(deliveryFee.multiply(new BigDecimal("0.03"))); // 3% bonus
        }

        // Long distance bonus (additional to commission rate bonus)
        if (distance != null && distance.compareTo(new BigDecimal("15.0")) > 0) {
            bonus = bonus.add(new BigDecimal("10.00")); // Fixed ₹10 bonus for 15+ km
        }

        return bonus.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculate penalty amount for poor performance
     */
    private BigDecimal calculatePenaltyAmount(Integer deliveryTimeMinutes, BigDecimal customerRating) {
        BigDecimal penalty = BigDecimal.ZERO;

        // Late delivery penalty (over 60 minutes)
        if (deliveryTimeMinutes != null && deliveryTimeMinutes > 60) {
            penalty = penalty.add(new BigDecimal("5.00")); // ₹5 penalty
        }

        // Low rating penalty (below 3 stars)
        if (customerRating != null && customerRating.compareTo(new BigDecimal("3.0")) < 0) {
            penalty = penalty.add(new BigDecimal("10.00")); // ₹10 penalty
        }

        return penalty.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Check if time is during peak hours
     */
    private boolean isPeakHours(LocalTime time) {
        return (time.isAfter(LocalTime.of(7, 0)) && time.isBefore(LocalTime.of(9, 0))) ||
               (time.isAfter(LocalTime.of(12, 0)) && time.isBefore(LocalTime.of(14, 0))) ||
               (time.isAfter(LocalTime.of(18, 0)) && time.isBefore(LocalTime.of(21, 0)));
    }

    /**
     * Check if delivery is on weekend
     */
    private boolean isWeekend(LocalDateTime deliveryTime) {
        int dayOfWeek = deliveryTime.getDayOfWeek().getValue();
        return dayOfWeek == 6 || dayOfWeek == 7; // Saturday or Sunday
    }

    /**
     * Get earnings summary for a delivery partner
     */
    public EarningsSummaryDTO getEarningsSummary(String partnerId, LocalDate startDate, LocalDate endDate) {
        try {
            Long partnerIdLong = Long.valueOf(partnerId);

            // Get total earnings
            BigDecimal totalEarnings = earningsRepository.getTotalEarningsByPartnerAndDateRange(
                partnerIdLong, startDate, endDate);

            BigDecimal totalCommission = earningsRepository.getTotalCommissionByPartnerAndDateRange(
                partnerIdLong, startDate, endDate);

            BigDecimal pendingAmount = earningsRepository.getTotalPendingAmount(partnerIdLong);

            // Get delivery count
            List<DeliveryPartnerEarnings> earnings = earningsRepository.findByPartnerIdAndDateRange(
                partnerIdLong, startDate, endDate);

            long totalDeliveries = earnings.size();

            // Calculate averages
            BigDecimal avgEarningPerDelivery = totalDeliveries > 0
                ? totalEarnings.divide(BigDecimal.valueOf(totalDeliveries), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

            Double avgRating = earnings.stream()
                .filter(e -> e.getCustomerRating() != null)
                .mapToDouble(e -> e.getCustomerRating().doubleValue())
                .average()
                .orElse(0.0);

            return EarningsSummaryDTO.builder()
                .partnerId(partnerId)
                .startDate(startDate)
                .endDate(endDate)
                .totalEarnings(totalEarnings)
                .totalCommission(totalCommission)
                .pendingAmount(pendingAmount)
                .totalDeliveries(totalDeliveries)
                .avgEarningPerDelivery(avgEarningPerDelivery)
                .avgCustomerRating(BigDecimal.valueOf(avgRating).setScale(2, RoundingMode.HALF_UP))
                .build();

        } catch (Exception e) {
            log.error("Error getting earnings summary for partner {}: {}", partnerId, e.getMessage(), e);
            throw new RuntimeException("Failed to get earnings summary: " + e.getMessage(), e);
        }
    }

    /**
     * Update earnings calculation for manual adjustments
     */
    @Transactional
    public DeliveryPartnerEarnings updateEarnings(Long earningsId, BigDecimal bonusAdjustment,
                                                 BigDecimal penaltyAdjustment, String reason) {
        try {
            DeliveryPartnerEarnings earnings = earningsRepository.findById(earningsId)
                .orElseThrow(() -> new RuntimeException("Earnings record not found: " + earningsId));

            // Apply adjustments
            if (bonusAdjustment != null) {
                earnings.setBonusAmount(earnings.getBonusAmount().add(bonusAdjustment));
            }

            if (penaltyAdjustment != null) {
                earnings.setPenaltyAmount(earnings.getPenaltyAmount().add(penaltyAdjustment));
            }

            // Recalculate earnings
            earnings.calculateEarnings();
            earnings.setUpdatedBy("manual-adjustment");
            earnings.setDeliveryNotes(earnings.getDeliveryNotes() + " | Adjustment: " + reason);

            DeliveryPartnerEarnings updated = earningsRepository.save(earnings);

            log.info("Earnings updated for ID {}: Bonus adjustment {}, Penalty adjustment {}, Reason: {}",
                earningsId, bonusAdjustment, penaltyAdjustment, reason);

            return updated;

        } catch (Exception e) {
            log.error("Error updating earnings {}: {}", earningsId, e.getMessage(), e);
            throw new RuntimeException("Failed to update earnings: " + e.getMessage(), e);
        }
    }

    // DTO Classes
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class EarningsSummaryDTO {
        private String partnerId;
        private LocalDate startDate;
        private LocalDate endDate;
        private BigDecimal totalEarnings;
        private BigDecimal totalCommission;
        private BigDecimal pendingAmount;
        private Long totalDeliveries;
        private BigDecimal avgEarningPerDelivery;
        private BigDecimal avgCustomerRating;
    }
}