package com.shopmanagement.service;

import com.shopmanagement.entity.*;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.DeliveryPartnerSettingsRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PartnerSelectionService {

    private final UserRepository userRepository;
    private final DeliveryPartnerSettingsRepository settingsRepository;
    private final OrderAssignmentRepository assignmentRepository;
    private final DeliveryFeeService deliveryFeeService;

    private static final List<OrderAssignment.AssignmentStatus> ACTIVE_STATUSES = Arrays.asList(
        OrderAssignment.AssignmentStatus.ASSIGNED,
        OrderAssignment.AssignmentStatus.ACCEPTED,
        OrderAssignment.AssignmentStatus.PICKED_UP,
        OrderAssignment.AssignmentStatus.IN_TRANSIT
    );

    /**
     * Find the best available partner for an order using intelligent selection
     */
    public User findBestPartnerForOrder(Order order) {
        log.info("Finding best partner for order {}", order.getId());

        // Get all available partners
        List<PartnerScore> scoredPartners = getAvailablePartnersWithScores(order);

        if (scoredPartners.isEmpty()) {
            log.warn("No available partners found for order {}", order.getId());
            return findPartnerAboutToFinish(order);
        }

        // Sort by score (highest first)
        scoredPartners.sort((a, b) -> Double.compare(b.getScore(), a.getScore()));

        // Log top candidates
        log.info("Top partner candidates for order {}:", order.getId());
        scoredPartners.stream().limit(3).forEach(ps ->
            log.info("  Partner {} ({}): Score = {}",
                ps.getPartner().getId(),
                ps.getPartner().getEmail(),
                String.format("%.2f", ps.getScore()))
        );

        User selectedPartner = scoredPartners.get(0).getPartner();
        log.info("Selected partner {} for order {} with score {}",
            selectedPartner.getId(), order.getId(),
            String.format("%.2f", scoredPartners.get(0).getScore()));

        return selectedPartner;
    }

    /**
     * Get available partners with calculated scores
     */
    private List<PartnerScore> getAvailablePartnersWithScores(Order order) {
        // Get online and available partners
        List<User> availablePartners = userRepository.findByRoleAndIsOnlineAndIsAvailable(
            User.UserRole.DELIVERY_PARTNER, true, true
        );

        // Filter partners who are not on ride
        availablePartners = availablePartners.stream()
            .filter(p -> p.getRideStatus() == null || p.getRideStatus() == User.RideStatus.AVAILABLE)
            .collect(Collectors.toList());

        // Check settings for auto-accept and work schedule
        List<PartnerScore> scoredPartners = new ArrayList<>();

        for (User partner : availablePartners) {
            // Check if partner is within working hours
            if (!isPartnerAvailableNow(partner)) {
                log.debug("Partner {} is outside work schedule", partner.getId());
                continue;
            }

            // Check if partner accepts deliveries in this radius
            if (!isWithinPartnerRadius(partner, order)) {
                log.debug("Partner {} is outside delivery radius for order", partner.getId());
                continue;
            }

            // Calculate score
            double score = calculatePartnerScore(partner, order);
            scoredPartners.add(new PartnerScore(partner, score));
        }

        return scoredPartners;
    }

    /**
     * Calculate score for a partner based on multiple factors
     */
    private double calculatePartnerScore(User partner, Order order) {
        double score = 100.0; // Start with base score

        // 1. Distance factor (40% weight) - Assuming we have location data
        double distance = calculateDistanceToShop(partner, order.getShop());
        if (distance <= 2.0) {
            score += 40.0; // Very close
        } else if (distance <= 5.0) {
            score += 30.0 - (distance - 2) * 3; // Gradual decrease
        } else if (distance <= 10.0) {
            score += 20.0 - (distance - 5) * 2;
        } else {
            score += Math.max(0, 10.0 - (distance - 10));
        }

        // 2. Performance factor (30% weight)
        // For User entity, we can add performance tracking fields later
        // For now, use basic completion rate calculation
        Long completedDeliveries = assignmentRepository.countCompletedAssignmentsByPartnerId(partner.getId());
        Long totalAssignments = assignmentRepository.countByDeliveryPartner(partner);

        if (totalAssignments > 0) {
            double completionRate = (double) completedDeliveries / totalAssignments;
            score += completionRate * 30.0; // Up to 30 points for completion rate
        }

        // 3. Current load factor (20% weight)
        Optional<OrderAssignment> currentAssignment = assignmentRepository
            .findCurrentAssignmentByPartnerId(partner.getId(), ACTIVE_STATUSES);

        if (currentAssignment.isEmpty()) {
            score += 20.0; // Partner is completely free
        } else {
            // Check if current order is almost complete
            OrderAssignment assignment = currentAssignment.get();
            if (assignment.getStatus() == OrderAssignment.AssignmentStatus.IN_TRANSIT) {
                score += 10.0; // Will be free soon
            } else if (assignment.getStatus() == OrderAssignment.AssignmentStatus.PICKED_UP) {
                score += 5.0; // Moderate availability
            }
        }

        // 4. Auto-accept bonus (10% weight)
        Optional<DeliveryPartnerSettings> settings = settingsRepository.findByPartnerId(partner.getId().toString());
        if (settings.isPresent() && Boolean.TRUE.equals(settings.get().getAutoAcceptOrders())) {
            score += 10.0; // Bonus for auto-accept enabled
        }

        // 5. Recent activity factor
        if (partner.getLastActivity() != null) {
            long minutesSinceActivity = java.time.Duration.between(
                partner.getLastActivity(), LocalDateTime.now()
            ).toMinutes();

            if (minutesSinceActivity <= 5) {
                score += 5.0; // Very recently active
            } else if (minutesSinceActivity <= 15) {
                score += 3.0; // Recently active
            }
        }

        return score;
    }

    /**
     * Check if partner is available based on work schedule
     */
    private boolean isPartnerAvailableNow(User partner) {
        Optional<DeliveryPartnerSettings> settings = settingsRepository
            .findByPartnerId(partner.getId().toString());

        if (settings.isEmpty() || !settings.get().getWorkScheduleEnabled()) {
            return true; // No schedule restrictions
        }

        DeliveryPartnerSettings partnerSettings = settings.get();
        LocalTime now = LocalTime.now();

        // Check time
        if (partnerSettings.getWorkStartTime() != null && partnerSettings.getWorkEndTime() != null) {
            if (now.isBefore(partnerSettings.getWorkStartTime()) ||
                now.isAfter(partnerSettings.getWorkEndTime())) {
                return false;
            }
        }

        // Check day of week
        int currentDay = LocalDateTime.now().getDayOfWeek().getValue();
        String workDays = partnerSettings.getWorkDays();
        if (workDays != null && !workDays.contains(String.valueOf(currentDay))) {
            return false;
        }

        return true;
    }

    /**
     * Check if order is within partner's delivery radius
     */
    private boolean isWithinPartnerRadius(User partner, Order order) {
        Optional<DeliveryPartnerSettings> settings = settingsRepository
            .findByPartnerId(partner.getId().toString());

        if (settings.isEmpty() || settings.get().getMaxDeliveryRadiusKm() == null) {
            return true; // No radius restriction
        }

        double distance = calculateDistanceToShop(partner, order.getShop());
        return distance <= settings.get().getMaxDeliveryRadiusKm();
    }

    /**
     * Calculate distance between partner and shop
     */
    private double calculateDistanceToShop(User partner, Shop shop) {
        // Get partner's last known location (if available)
        // For now, using a default calculation

        if (shop.getLatitude() == null || shop.getLongitude() == null) {
            return 5.0; // Default 5km if shop location unknown
        }

        // In a real implementation, we'd get partner's current location
        // For now, simulate with random nearby location
        double partnerLat = shop.getLatitude().doubleValue() + (Math.random() - 0.5) * 0.1;
        double partnerLon = shop.getLongitude().doubleValue() + (Math.random() - 0.5) * 0.1;

        return deliveryFeeService.calculateDistance(
            partnerLat, partnerLon,
            shop.getLatitude().doubleValue(),
            shop.getLongitude().doubleValue()
        );
    }

    /**
     * Find a partner who is about to finish their current delivery
     */
    private User findPartnerAboutToFinish(Order order) {
        log.info("Looking for partners about to finish current delivery");

        List<User> busyPartners = userRepository.findByRoleAndIsOnline(
            User.UserRole.DELIVERY_PARTNER, true
        ).stream()
            .filter(p -> p.getRideStatus() == User.RideStatus.ON_RIDE)
            .collect(Collectors.toList());

        for (User partner : busyPartners) {
            Optional<OrderAssignment> currentAssignment = assignmentRepository
                .findCurrentAssignmentByPartnerId(partner.getId(), ACTIVE_STATUSES);

            if (currentAssignment.isPresent()) {
                OrderAssignment assignment = currentAssignment.get();

                // Check if in transit (almost done)
                if (assignment.getStatus() == OrderAssignment.AssignmentStatus.IN_TRANSIT) {
                    if (assignment.getPickupTime() != null) {
                        long minutesSincePickup = java.time.Duration.between(
                            assignment.getPickupTime(), LocalDateTime.now()
                        ).toMinutes();

                        if (minutesSincePickup > 15) {
                            log.info("Partner {} should finish soon (in transit for {} minutes)",
                                partner.getId(), minutesSincePickup);
                            return partner;
                        }
                    }
                }
            }
        }

        return null;
    }

    /**
     * Get available partners count by status
     */
    public Map<String, Long> getPartnerAvailabilityStats() {
        Map<String, Long> stats = new HashMap<>();

        List<User> allPartners = userRepository.findByRole(User.UserRole.DELIVERY_PARTNER);

        stats.put("total", (long) allPartners.size());
        stats.put("online", allPartners.stream().filter(User::getIsOnline).count());
        stats.put("available", allPartners.stream()
            .filter(p -> p.getIsOnline() && p.getIsAvailable())
            .count());
        stats.put("onRide", allPartners.stream()
            .filter(p -> p.getRideStatus() == User.RideStatus.ON_RIDE)
            .count());
        stats.put("offline", allPartners.stream()
            .filter(p -> !p.getIsOnline())
            .count());

        return stats;
    }

    /**
     * Inner class to hold partner with score
     */
    private static class PartnerScore {
        private final User partner;
        private final double score;

        public PartnerScore(User partner, double score) {
            this.partner = partner;
            this.score = score;
        }

        public User getPartner() {
            return partner;
        }

        public double getScore() {
            return score;
        }
    }

    /**
     * Get partners sorted by proximity to a location
     */
    public List<User> getPartnersByProximity(double latitude, double longitude, int maxCount) {
        List<User> availablePartners = userRepository.findByRoleAndIsOnlineAndIsAvailable(
            User.UserRole.DELIVERY_PARTNER, true, true
        );

        // Calculate distances and sort
        Map<User, Double> partnerDistances = new HashMap<>();
        for (User partner : availablePartners) {
            // In real implementation, get partner's actual location
            // For now, use simulated distance
            double distance = Math.random() * 10; // Simulated 0-10km
            partnerDistances.put(partner, distance);
        }

        return partnerDistances.entrySet().stream()
            .sorted(Map.Entry.comparingByValue())
            .limit(maxCount)
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
    }
}