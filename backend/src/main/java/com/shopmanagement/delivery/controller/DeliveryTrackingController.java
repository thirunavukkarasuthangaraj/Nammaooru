package com.shopmanagement.delivery.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.service.DeliveryTrackingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery/tracking")
@RequiredArgsConstructor
@Slf4j
public class DeliveryTrackingController {

    private final DeliveryTrackingService trackingService;

    @PostMapping("/update-location")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<DeliveryTrackingResponse>> updateLocation(
            @Valid @RequestBody LocationUpdateRequest request) {
        log.debug("Location update request received for assignment: {}", request.getAssignmentId());
        
        try {
            DeliveryTrackingResponse response = trackingService.updateLocation(request);
            return ResponseUtil.success(response, "Location updated successfully");
        } catch (Exception e) {
            log.error("Error updating location: {}", e.getMessage());
            return ResponseUtil.error("Failed to update location: " + e.getMessage());
        }
    }

    @GetMapping("/assignment/{assignmentId}/latest")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<DeliveryTrackingResponse>> getLatestTracking(@PathVariable Long assignmentId) {
        return trackingService.getLatestTracking(assignmentId)
                .map(tracking -> ResponseUtil.success(tracking))
                .orElse(ResponseUtil.error("No tracking data found"));
    }

    @GetMapping("/assignment/{assignmentId}/history")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<List<DeliveryTrackingResponse>>> getTrackingHistory(@PathVariable Long assignmentId) {
        List<DeliveryTrackingResponse> history = trackingService.getTrackingHistory(assignmentId);
        return ResponseUtil.success(history);
    }

    @GetMapping("/assignment/{assignmentId}/full")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<DeliveryTrackingResponse>> getTrackingWithHistory(@PathVariable Long assignmentId) {
        DeliveryTrackingResponse tracking = trackingService.getTrackingWithHistory(assignmentId);
        if (tracking != null) {
            return ResponseUtil.success(tracking);
        } else {
            return ResponseUtil.error("No tracking data found");
        }
    }

    @GetMapping("/assignment/{assignmentId}/range")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<DeliveryTrackingResponse>>> getTrackingByTimeRange(
            @PathVariable Long assignmentId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime) {
        List<DeliveryTrackingResponse> tracking = trackingService.getTrackingByTimeRange(assignmentId, startTime, endTime);
        return ResponseUtil.success(tracking);
    }

    @GetMapping("/partner/{partnerId}/recent")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<List<DeliveryTrackingResponse>>> getRecentPartnerTracking(
            @PathVariable Long partnerId,
            @RequestParam(defaultValue = "60") int minutes) {
        List<DeliveryTrackingResponse> tracking = trackingService.getRecentPartnerTracking(partnerId, minutes);
        return ResponseUtil.success(tracking);
    }

    @GetMapping("/assignment/{assignmentId}/count")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<Long>> getTrackingPointCount(@PathVariable Long assignmentId) {
        Long count = trackingService.getTrackingPointCount(assignmentId);
        return ResponseUtil.success(count);
    }

    @GetMapping("/alerts/low-battery")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<List<DeliveryTrackingResponse>>> getLowBatteryAlerts() {
        List<DeliveryTrackingResponse> alerts = trackingService.getLowBatteryAlerts();
        return ResponseUtil.success(alerts);
    }

    @PostMapping("/partner/{partnerId}/online-status")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> updatePartnerOnlineStatus(
            @PathVariable Long partnerId,
            @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isOnline = request.get("isOnline");
            trackingService.updatePartnerOnlineStatus(partnerId, isOnline);
            return ResponseUtil.success("Online status updated successfully");
        } catch (Exception e) {
            log.error("Error updating online status: {}", e.getMessage());
            return ResponseUtil.error("Failed to update online status: " + e.getMessage());
        }
    }

    @GetMapping("/assignment/{assignmentId}/is-moving")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Boolean>> isPartnerMoving(@PathVariable Long assignmentId) {
        boolean isMoving = trackingService.isPartnerMoving(assignmentId);
        return ResponseUtil.success(isMoving);
    }

    @GetMapping("/assignment/{assignmentId}/is-recent")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Boolean>> isTrackingRecent(
            @PathVariable Long assignmentId,
            @RequestParam(defaultValue = "5") int minutes) {
        boolean isRecent = trackingService.isTrackingRecent(assignmentId, minutes);
        return ResponseUtil.success(isRecent);
    }

    @PostMapping("/cleanup")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> cleanupOldTrackingData(
            @RequestParam(defaultValue = "30") int daysToKeep) {
        try {
            trackingService.cleanupOldTrackingData(daysToKeep);
            return ResponseUtil.success("Old tracking data cleaned up successfully");
        } catch (Exception e) {
            log.error("Error cleaning up tracking data: {}", e.getMessage());
            return ResponseUtil.error("Failed to cleanup tracking data: " + e.getMessage());
        }
    }
}