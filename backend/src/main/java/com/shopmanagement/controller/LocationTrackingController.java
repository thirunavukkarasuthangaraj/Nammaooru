package com.shopmanagement.controller;

import com.shopmanagement.entity.DeliveryPartnerLocation;
import com.shopmanagement.service.LocationTrackingService;
import com.shopmanagement.service.LocationTrackingService.LocationUpdateRequest;
import com.shopmanagement.service.LocationTrackingService.ETAResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/location")
@RequiredArgsConstructor
public class LocationTrackingController {

    private final LocationTrackingService locationTrackingService;

    /**
     * Update delivery partner location
     * POST /api/location/partners/{partnerId}/update
     */
    @PostMapping("/partners/{partnerId}/update")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<?> updateLocation(
            @PathVariable Long partnerId,
            @RequestBody LocationUpdateRequest request) {
        try {
            request.setPartnerId(partnerId);
            DeliveryPartnerLocation location = locationTrackingService.updatePartnerLocation(request);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Location updated successfully",
                "location", Map.of(
                    "id", location.getId(),
                    "latitude", location.getLatitude(),
                    "longitude", location.getLongitude(),
                    "recordedAt", location.getRecordedAt(),
                    "isMoving", location.getIsMoving()
                )
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to update location: " + e.getMessage()
            ));
        }
    }

    /**
     * Get current location of delivery partner
     * GET /api/location/partners/{partnerId}/current
     */
    @GetMapping("/partners/{partnerId}/current")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> getCurrentLocation(@PathVariable Long partnerId) {
        try {
            Optional<DeliveryPartnerLocation> location = locationTrackingService.getCurrentLocation(partnerId);

            if (location.isPresent()) {
                DeliveryPartnerLocation loc = location.get();
                return ResponseEntity.ok(Map.of(
                    "success", true,
                    "location", Map.of(
                        "latitude", loc.getLatitude(),
                        "longitude", loc.getLongitude(),
                        "accuracy", loc.getAccuracy(),
                        "speed", loc.getSpeed(),
                        "heading", loc.getHeading(),
                        "recordedAt", loc.getRecordedAt(),
                        "isMoving", loc.getIsMoving(),
                        "assignmentId", loc.getAssignmentId(),
                        "orderStatus", loc.getOrderStatus()
                    )
                ));
            } else {
                return ResponseEntity.ok(Map.of(
                    "success", false,
                    "message", "No location data available"
                ));
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to get current location: " + e.getMessage()
            ));
        }
    }

    /**
     * Get location history for a delivery partner
     * GET /api/location/partners/{partnerId}/history
     */
    @GetMapping("/partners/{partnerId}/history")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<?> getLocationHistory(
            @PathVariable Long partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime) {
        try {
            List<DeliveryPartnerLocation> locations = locationTrackingService.getLocationHistory(partnerId, startTime, endTime);

            List<Map<String, Object>> locationData = locations.stream()
                .map(loc -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("latitude", loc.getLatitude());
                    map.put("longitude", loc.getLongitude());
                    map.put("speed", loc.getSpeed());
                    map.put("recordedAt", loc.getRecordedAt());
                    map.put("isMoving", loc.getIsMoving());
                    map.put("assignmentId", loc.getAssignmentId() != null ? loc.getAssignmentId() : "");
                    map.put("orderStatus", loc.getOrderStatus() != null ? loc.getOrderStatus() : "");
                    return map;
                })
                .toList();

            return ResponseEntity.ok(Map.of(
                "success", true,
                "locations", locationData,
                "count", locations.size()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to get location history: " + e.getMessage()
            ));
        }
    }

    /**
     * Get delivery tracking route for an assignment
     * GET /api/location/assignments/{assignmentId}/route
     */
    @GetMapping("/assignments/{assignmentId}/route")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> getDeliveryRoute(
            @PathVariable Long assignmentId,
            @RequestParam Long partnerId) {
        try {
            List<DeliveryPartnerLocation> route = locationTrackingService.getDeliveryRoute(partnerId, assignmentId);

            List<Map<String, Object>> routeData = route.stream()
                .map(loc -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("latitude", loc.getLatitude());
                    map.put("longitude", loc.getLongitude());
                    map.put("recordedAt", loc.getRecordedAt());
                    map.put("orderStatus", loc.getOrderStatus());
                    map.put("speed", loc.getSpeed() != null ? loc.getSpeed() : 0);
                    return map;
                })
                .toList();

            return ResponseEntity.ok(Map.of(
                "success", true,
                "route", routeData,
                "assignmentId", assignmentId,
                "partnerId", partnerId
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to get delivery route: " + e.getMessage()
            ));
        }
    }

    /**
     * Calculate ETA to destination
     * POST /api/location/partners/{partnerId}/eta
     */
    @PostMapping("/partners/{partnerId}/eta")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> calculateETA(
            @PathVariable Long partnerId,
            @RequestBody Map<String, Double> destination) {
        try {
            Double destLat = destination.get("latitude");
            Double destLng = destination.get("longitude");

            if (destLat == null || destLng == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Destination latitude and longitude are required"
                ));
            }

            ETAResponse eta = locationTrackingService.calculateETA(partnerId, destLat, destLng);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "eta", eta
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to calculate ETA: " + e.getMessage()
            ));
        }
    }

    /**
     * Find partners near a location
     * POST /api/location/nearby-partners
     */
    @PostMapping("/nearby-partners")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> findNearbyPartners(@RequestBody Map<String, Object> request) {
        try {
            Double latitude = ((Number) request.get("latitude")).doubleValue();
            Double longitude = ((Number) request.get("longitude")).doubleValue();
            Double radius = request.containsKey("radius") ?
                ((Number) request.get("radius")).doubleValue() : 5.0; // Default 5km

            List<DeliveryPartnerLocation> nearbyPartners = locationTrackingService
                .findPartnersNearLocation(latitude, longitude, radius);

            List<Map<String, Object>> partnerData = nearbyPartners.stream()
                .map(loc -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("partnerId", loc.getPartnerId());
                    map.put("latitude", loc.getLatitude());
                    map.put("longitude", loc.getLongitude());
                    map.put("lastSeen", loc.getRecordedAt());
                    map.put("isMoving", loc.getIsMoving());
                    map.put("speed", loc.getSpeed() != null ? loc.getSpeed() : 0);
                    map.put("assignmentId", loc.getAssignmentId());
                    map.put("orderStatus", loc.getOrderStatus());
                    return map;
                })
                .toList();

            return ResponseEntity.ok(Map.of(
                "success", true,
                "partners", partnerData,
                "searchRadius", radius,
                "count", partnerData.size()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to find nearby partners: " + e.getMessage()
            ));
        }
    }

    /**
     * Check if partner is online
     * GET /api/location/partners/{partnerId}/online-status
     */
    @GetMapping("/partners/{partnerId}/online-status")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> getOnlineStatus(@PathVariable Long partnerId) {
        try {
            boolean isOnline = locationTrackingService.isPartnerOnline(partnerId);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "partnerId", partnerId,
                "isOnline", isOnline,
                "lastChecked", LocalDateTime.now()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to check online status: " + e.getMessage()
            ));
        }
    }

    /**
     * Get partner activity summary
     * GET /api/location/partners/{partnerId}/activity
     */
    @GetMapping("/partners/{partnerId}/activity")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<?> getActivitySummary(
            @PathVariable Long partnerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDateTime date) {
        try {
            Map<String, Object> summary = locationTrackingService.getPartnerActivitySummary(partnerId, date);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "partnerId", partnerId,
                "date", date.toLocalDate(),
                "summary", summary
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Failed to get activity summary: " + e.getMessage()
            ));
        }
    }
}