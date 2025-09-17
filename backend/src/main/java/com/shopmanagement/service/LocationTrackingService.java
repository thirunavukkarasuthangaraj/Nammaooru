package com.shopmanagement.service;

import com.shopmanagement.entity.DeliveryPartnerLocation;
import com.shopmanagement.repository.DeliveryPartnerLocationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class LocationTrackingService {

    private final DeliveryPartnerLocationRepository locationRepository;

    /**
     * Update delivery partner location
     */
    @Transactional
    public DeliveryPartnerLocation updatePartnerLocation(LocationUpdateRequest request) {
        try {
            DeliveryPartnerLocation location = DeliveryPartnerLocation.builder()
                .partnerId(request.getPartnerId())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .speed(request.getSpeed())
                .heading(request.getHeading())
                .altitude(request.getAltitude())
                .recordedAt(request.getTimestamp() != null ? request.getTimestamp() : LocalDateTime.now())
                .isMoving(request.getSpeed() != null && request.getSpeed().compareTo(BigDecimal.valueOf(1.0)) > 0)
                .batteryLevel(request.getBatteryLevel())
                .networkType(request.getNetworkType())
                .assignmentId(request.getAssignmentId())
                .orderStatus(request.getOrderStatus())
                .build();

            DeliveryPartnerLocation saved = locationRepository.save(location);
            log.info("Updated location for partner {} at ({}, {})",
                request.getPartnerId(), request.getLatitude(), request.getLongitude());

            return saved;
        } catch (Exception e) {
            log.error("Error updating location for partner {}: {}", request.getPartnerId(), e.getMessage());
            throw new RuntimeException("Failed to update location", e);
        }
    }

    /**
     * Get current location of a delivery partner
     */
    public Optional<DeliveryPartnerLocation> getCurrentLocation(Long partnerId) {
        return locationRepository.findLatestLocationByPartnerId(partnerId);
    }

    /**
     * Get location history for a partner
     */
    public List<DeliveryPartnerLocation> getLocationHistory(Long partnerId, LocalDateTime startTime, LocalDateTime endTime) {
        return locationRepository.findLocationsByPartnerIdAndTimeRange(partnerId, startTime, endTime);
    }

    /**
     * Get delivery tracking route for an assignment
     */
    public List<DeliveryPartnerLocation> getDeliveryRoute(Long partnerId, Long assignmentId) {
        List<String> activeStatuses = List.of("ACCEPTED", "PICKED_UP", "IN_TRANSIT");
        return locationRepository.findDeliveryTrackingLocations(partnerId, assignmentId, activeStatuses);
    }

    /**
     * Find partners near a location
     */
    public List<DeliveryPartnerLocation> findPartnersNearLocation(double latitude, double longitude, double radiusKm) {
        LocalDateTime since = LocalDateTime.now().minusMinutes(15); // Only consider recent locations
        return locationRepository.findPartnersNearLocation(latitude, longitude, radiusKm, since);
    }

    /**
     * Check if partner is online (has recent location updates)
     */
    public boolean isPartnerOnline(Long partnerId) {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(10);
        return locationRepository.hasRecentLocationUpdate(partnerId, threshold);
    }

    /**
     * Calculate ETA to destination
     */
    public ETAResponse calculateETA(Long partnerId, double destLatitude, double destLongitude) {
        Optional<DeliveryPartnerLocation> currentLocation = getCurrentLocation(partnerId);

        if (currentLocation.isEmpty()) {
            return ETAResponse.builder()
                .estimatedMinutes(null)
                .distance(null)
                .error("Current location not available")
                .build();
        }

        DeliveryPartnerLocation location = currentLocation.get();
        double distance = calculateDistance(
            location.getLatitude().doubleValue(),
            location.getLongitude().doubleValue(),
            destLatitude,
            destLongitude
        );

        // Estimate time based on average speed or default speed
        double averageSpeed = 20.0; // km/h default urban speed
        if (location.getSpeed() != null && location.getSpeed().doubleValue() > 0) {
            averageSpeed = location.getSpeed().doubleValue() * 3.6; // Convert m/s to km/h
        }

        int estimatedMinutes = (int) Math.ceil((distance / averageSpeed) * 60);

        return ETAResponse.builder()
            .estimatedMinutes(estimatedMinutes)
            .distance(distance)
            .currentLatitude(location.getLatitude().doubleValue())
            .currentLongitude(location.getLongitude().doubleValue())
            .lastUpdated(location.getRecordedAt())
            .build();
    }

    /**
     * Calculate distance between two points using Haversine formula
     */
    public double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Radius of the earth in km

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Cleanup old location data
     */
    @Transactional
    public void cleanupOldLocations() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(30); // Keep 30 days of data
        try {
            locationRepository.deleteLocationsBefore(cutoff);
            log.info("Cleaned up location data older than {}", cutoff);
        } catch (Exception e) {
            log.error("Error cleaning up old locations: {}", e.getMessage());
        }
    }

    /**
     * Get partner activity summary
     */
    public Map<String, Object> getPartnerActivitySummary(Long partnerId, LocalDateTime date) {
        List<DeliveryPartnerLocation> locations = locationRepository.findLocationsByPartnerIdAndDate(partnerId, date);

        if (locations.isEmpty()) {
            return Map.of(
                "totalDistance", 0.0,
                "activeTime", 0,
                "avgSpeed", 0.0,
                "locationUpdates", 0
            );
        }

        double totalDistance = 0.0;
        double totalSpeed = 0.0;
        int speedCount = 0;

        for (int i = 1; i < locations.size(); i++) {
            DeliveryPartnerLocation prev = locations.get(i - 1);
            DeliveryPartnerLocation curr = locations.get(i);

            double distance = calculateDistance(
                prev.getLatitude().doubleValue(),
                prev.getLongitude().doubleValue(),
                curr.getLatitude().doubleValue(),
                curr.getLongitude().doubleValue()
            );
            totalDistance += distance;

            if (curr.getSpeed() != null && curr.getSpeed().doubleValue() > 0) {
                totalSpeed += curr.getSpeed().doubleValue();
                speedCount++;
            }
        }

        return Map.of(
            "totalDistance", Math.round(totalDistance * 100.0) / 100.0,
            "activeTime", locations.size() * 30, // Assuming 30-second intervals
            "avgSpeed", speedCount > 0 ? Math.round((totalSpeed / speedCount) * 100.0) / 100.0 : 0.0,
            "locationUpdates", locations.size()
        );
    }

    // DTO classes
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class LocationUpdateRequest {
        private Long partnerId;
        private BigDecimal latitude;
        private BigDecimal longitude;
        private BigDecimal accuracy;
        private BigDecimal speed;
        private BigDecimal heading;
        private BigDecimal altitude;
        private LocalDateTime timestamp;
        private Integer batteryLevel;
        private String networkType;
        private Long assignmentId;
        private String orderStatus;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ETAResponse {
        private Integer estimatedMinutes;
        private Double distance;
        private Double currentLatitude;
        private Double currentLongitude;
        private LocalDateTime lastUpdated;
        private String error;
    }
}