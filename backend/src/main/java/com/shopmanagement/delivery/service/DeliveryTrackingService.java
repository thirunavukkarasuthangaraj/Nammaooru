package com.shopmanagement.delivery.service;

import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.entity.*;
import com.shopmanagement.delivery.mapper.DeliveryPartnerMapper;
import com.shopmanagement.delivery.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeliveryTrackingService {

    private final DeliveryTrackingRepository trackingRepository;
    private final OrderAssignmentRepository assignmentRepository;
    private final DeliveryPartnerRepository partnerRepository;
    private final DeliveryPartnerMapper mapper;

    @Transactional
    public DeliveryTrackingResponse updateLocation(LocationUpdateRequest request) {
        log.debug("Updating location for assignment {}", request.getAssignmentId());

        // Validate assignment
        OrderAssignment assignment = getAssignmentEntity(request.getAssignmentId());
        validateAssignmentForTracking(assignment);

        // Create tracking record
        DeliveryTracking tracking = createTrackingRecord(request, assignment);
        DeliveryTracking savedTracking = trackingRepository.save(tracking);

        // Update partner's current location
        updatePartnerLocation(assignment.getDeliveryPartner(), request);

        log.debug("Successfully updated location for assignment {}", request.getAssignmentId());
        return mapper.toTrackingResponse(savedTracking);
    }

    public Optional<DeliveryTrackingResponse> getLatestTracking(Long assignmentId) {
        return trackingRepository.findLatestTrackingByAssignment(assignmentId)
                .map(mapper::toTrackingResponse);
    }

    public List<DeliveryTrackingResponse> getTrackingHistory(Long assignmentId) {
        List<DeliveryTracking> trackingHistory = trackingRepository
                .findByOrderAssignmentIdOrderByTrackedAtDesc(assignmentId);
        
        return trackingHistory.stream()
                .map(mapper::toTrackingResponse)
                .toList();
    }

    public DeliveryTrackingResponse getTrackingWithHistory(Long assignmentId) {
        Optional<DeliveryTracking> latestTracking = trackingRepository
                .findLatestTrackingByAssignment(assignmentId);
        
        if (latestTracking.isEmpty()) {
            return null;
        }

        DeliveryTrackingResponse response = mapper.toTrackingResponse(latestTracking.get());
        
        // Add tracking history
        List<DeliveryTracking> history = trackingRepository
                .findByOrderAssignmentIdOrderByTrackedAtDesc(assignmentId);
        response.setTrackingHistory(mapper.toTrackingPoints(history));
        
        return response;
    }

    public List<DeliveryTrackingResponse> getTrackingByTimeRange(Long assignmentId, 
                                                               LocalDateTime startTime, 
                                                               LocalDateTime endTime) {
        List<DeliveryTracking> trackingHistory = trackingRepository
                .findTrackingHistoryByTimeRange(assignmentId, startTime, endTime);
        
        return trackingHistory.stream()
                .map(mapper::toTrackingResponse)
                .toList();
    }

    public List<DeliveryTrackingResponse> getRecentPartnerTracking(Long partnerId, int minutes) {
        LocalDateTime since = LocalDateTime.now().minusMinutes(minutes);
        List<DeliveryTracking> recentTracking = trackingRepository
                .findRecentTrackingByPartner(partnerId, since);
        
        return recentTracking.stream()
                .map(mapper::toTrackingResponse)
                .toList();
    }

    public Long getTrackingPointCount(Long assignmentId) {
        return trackingRepository.countTrackingPointsByAssignment(assignmentId);
    }

    @Transactional
    public void cleanupOldTrackingData(int daysToKeep) {
        log.info("Cleaning up tracking data older than {} days", daysToKeep);
        
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(daysToKeep);
        
        // Get all completed assignments
        List<OrderAssignment> completedAssignments = assignmentRepository
                .findByStatus(OrderAssignment.AssignmentStatus.DELIVERED);
        
        for (OrderAssignment assignment : completedAssignments) {
            if (assignment.getDeliveryTime() != null && 
                assignment.getDeliveryTime().isBefore(cutoffDate)) {
                
                trackingRepository.deleteByOrderAssignmentIdAndTrackedAtBefore(
                        assignment.getId(), cutoffDate);
                
                log.debug("Cleaned up tracking data for assignment {}", assignment.getId());
            }
        }
    }

    public List<DeliveryTrackingResponse> getLowBatteryAlerts() {
        List<DeliveryTracking> lowBatteryTracking = trackingRepository.findLowBatteryTracking();
        
        return lowBatteryTracking.stream()
                .map(mapper::toTrackingResponse)
                .toList();
    }

    @Transactional
    public void updatePartnerOnlineStatus(Long partnerId, boolean isOnline) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setIsOnline(isOnline);
        
        if (!isOnline) {
            partner.setIsAvailable(false);
        }
        
        partnerRepository.save(partner);
        log.info("Updated partner {} online status to: {}", partnerId, isOnline);
    }

    // Utility methods for real-time tracking

    public boolean isPartnerMoving(Long assignmentId) {
        Optional<DeliveryTracking> latestTracking = trackingRepository
                .findLatestTrackingByAssignment(assignmentId);
        
        return latestTracking.map(DeliveryTracking::getIsMoving).orElse(false);
    }

    public boolean isTrackingRecent(Long assignmentId, int minutes) {
        Optional<DeliveryTracking> latestTracking = trackingRepository
                .findLatestTrackingByAssignment(assignmentId);
        
        if (latestTracking.isEmpty()) {
            return false;
        }
        
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(minutes);
        return latestTracking.get().getTrackedAt().isAfter(cutoff);
    }

    // Private helper methods

    private OrderAssignment getAssignmentEntity(Long assignmentId) {
        return assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new IllegalArgumentException("Assignment not found: " + assignmentId));
    }

    private DeliveryPartner getPartnerEntity(Long partnerId) {
        return partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("Partner not found: " + partnerId));
    }

    private void validateAssignmentForTracking(OrderAssignment assignment) {
        if (assignment.getStatus() != OrderAssignment.AssignmentStatus.ACCEPTED &&
            assignment.getStatus() != OrderAssignment.AssignmentStatus.PICKED_UP &&
            assignment.getStatus() != OrderAssignment.AssignmentStatus.IN_TRANSIT) {
            
            throw new IllegalStateException("Assignment is not in a trackable state: " + assignment.getStatus());
        }
    }

    private DeliveryTracking createTrackingRecord(LocationUpdateRequest request, OrderAssignment assignment) {
        return DeliveryTracking.builder()
                .orderAssignment(assignment)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .altitude(request.getAltitude())
                .speed(request.getSpeed())
                .heading(request.getHeading())
                .trackedAt(request.getTrackedAt() != null ? request.getTrackedAt() : LocalDateTime.now())
                .batteryLevel(request.getBatteryLevel())
                .isMoving(request.getIsMoving())
                .estimatedArrivalTime(request.getEstimatedArrivalTime())
                .distanceToDestination(request.getDistanceToDestination())
                .build();
    }

    private void updatePartnerLocation(DeliveryPartner partner, LocationUpdateRequest request) {
        partner.setCurrentLatitude(request.getLatitude());
        partner.setCurrentLongitude(request.getLongitude());
        partner.setLastLocationUpdate(LocalDateTime.now());
        partnerRepository.save(partner);
    }
}