package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.DeliveryTracking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryTrackingRepository extends JpaRepository<DeliveryTracking, Long> {

    List<DeliveryTracking> findByOrderAssignmentId(Long assignmentId);
    
    List<DeliveryTracking> findByOrderAssignmentIdOrderByTrackedAtDesc(Long assignmentId);
    
    @Query("SELECT dt FROM DeliveryTracking dt WHERE dt.orderAssignment.id = :assignmentId ORDER BY dt.trackedAt DESC LIMIT 1")
    Optional<DeliveryTracking> findLatestTrackingByAssignment(@Param("assignmentId") Long assignmentId);
    
    @Query("""
        SELECT dt FROM DeliveryTracking dt 
        WHERE dt.orderAssignment.id = :assignmentId 
        AND dt.trackedAt BETWEEN :startTime AND :endTime 
        ORDER BY dt.trackedAt ASC
    """)
    List<DeliveryTracking> findTrackingHistoryByTimeRange(
            @Param("assignmentId") Long assignmentId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime
    );
    
    @Query("""
        SELECT dt FROM DeliveryTracking dt 
        WHERE dt.orderAssignment.deliveryPartner.id = :partnerId 
        AND dt.trackedAt >= :since 
        ORDER BY dt.trackedAt DESC
    """)
    List<DeliveryTracking> findRecentTrackingByPartner(
            @Param("partnerId") Long partnerId,
            @Param("since") LocalDateTime since
    );
    
    @Query("SELECT COUNT(dt) FROM DeliveryTracking dt WHERE dt.orderAssignment.id = :assignmentId")
    Long countTrackingPointsByAssignment(@Param("assignmentId") Long assignmentId);
    
    @Query("""
        SELECT dt FROM DeliveryTracking dt 
        WHERE dt.orderAssignment.id = :assignmentId 
        AND dt.isMoving = true 
        ORDER BY dt.trackedAt DESC
    """)
    List<DeliveryTracking> findMovementTrackingByAssignment(@Param("assignmentId") Long assignmentId);
    
    @Query("SELECT dt FROM DeliveryTracking dt WHERE dt.batteryLevel IS NOT NULL AND dt.batteryLevel < 20")
    List<DeliveryTracking> findLowBatteryTracking();
    
    void deleteByOrderAssignmentIdAndTrackedAtBefore(Long assignmentId, LocalDateTime cutoffDate);
    
    @Query("SELECT dt FROM DeliveryTracking dt WHERE dt.orderAssignment.deliveryPartner.id = :partnerId ORDER BY dt.trackedAt DESC")
    Optional<DeliveryTracking> findTopByPartnerIdOrderByTrackedAtDesc(@Param("partnerId") Long partnerId);
    
    @Query("""
        SELECT dt FROM DeliveryTracking dt 
        WHERE dt.orderAssignment.deliveryPartner.id = :partnerId 
        AND dt.trackedAt > :trackedAt 
        ORDER BY dt.trackedAt DESC
    """)
    List<DeliveryTracking> findByPartnerIdAndTrackedAtAfterOrderByTrackedAtDesc(@Param("partnerId") Long partnerId, @Param("trackedAt") LocalDateTime trackedAt);
}