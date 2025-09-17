package com.shopmanagement.repository;

import com.shopmanagement.entity.DeliveryPartnerLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerLocationRepository extends JpaRepository<DeliveryPartnerLocation, Long> {

    /**
     * Find the latest location for a specific delivery partner
     */
    @Query("SELECT dpl FROM DeliveryPartnerLocation dpl WHERE dpl.partnerId = :partnerId ORDER BY dpl.recordedAt DESC")
    Optional<DeliveryPartnerLocation> findLatestLocationByPartnerId(@Param("partnerId") Long partnerId);

    /**
     * Find all locations for a partner within a time range
     */
    @Query("SELECT dpl FROM DeliveryPartnerLocation dpl WHERE dpl.partnerId = :partnerId " +
           "AND dpl.recordedAt BETWEEN :startTime AND :endTime ORDER BY dpl.recordedAt DESC")
    List<DeliveryPartnerLocation> findLocationsByPartnerIdAndTimeRange(
        @Param("partnerId") Long partnerId,
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );

    /**
     * Find locations for a specific assignment
     */
    @Query("SELECT dpl FROM DeliveryPartnerLocation dpl WHERE dpl.assignmentId = :assignmentId ORDER BY dpl.recordedAt ASC")
    List<DeliveryPartnerLocation> findLocationsByAssignmentId(@Param("assignmentId") Long assignmentId);

    /**
     * Find partners near a specific location (within radius in kilometers)
     * Using Haversine formula for distance calculation
     */
    @Query(value = "SELECT * FROM delivery_partner_locations dpl WHERE " +
           "(6371 * acos(cos(radians(:latitude)) * cos(radians(latitude)) * " +
           "cos(radians(longitude) - radians(:longitude)) + sin(radians(:latitude)) * " +
           "sin(radians(latitude)))) <= :radiusKm " +
           "AND dpl.recorded_at >= :since " +
           "ORDER BY dpl.recorded_at DESC",
           nativeQuery = true)
    List<DeliveryPartnerLocation> findPartnersNearLocation(
        @Param("latitude") Double latitude,
        @Param("longitude") Double longitude,
        @Param("radiusKm") Double radiusKm,
        @Param("since") LocalDateTime since
    );

    /**
     * Delete old location records (for cleanup)
     */
    @Query("DELETE FROM DeliveryPartnerLocation dpl WHERE dpl.recordedAt < :cutoffTime")
    void deleteLocationsBefore(@Param("cutoffTime") LocalDateTime cutoffTime);

    /**
     * Get location history for a partner on a specific date
     */
    @Query("SELECT dpl FROM DeliveryPartnerLocation dpl WHERE dpl.partnerId = :partnerId " +
           "AND DATE(dpl.recordedAt) = DATE(:date) ORDER BY dpl.recordedAt ASC")
    List<DeliveryPartnerLocation> findLocationsByPartnerIdAndDate(
        @Param("partnerId") Long partnerId,
        @Param("date") LocalDateTime date
    );

    /**
     * Get the latest location for multiple partners
     */
    @Query("SELECT dpl1 FROM DeliveryPartnerLocation dpl1 WHERE dpl1.partnerId IN :partnerIds " +
           "AND dpl1.recordedAt = (SELECT MAX(dpl2.recordedAt) FROM DeliveryPartnerLocation dpl2 " +
           "WHERE dpl2.partnerId = dpl1.partnerId)")
    List<DeliveryPartnerLocation> findLatestLocationsForPartners(@Param("partnerIds") List<Long> partnerIds);

    /**
     * Check if partner has recent location updates (for online status)
     */
    @Query("SELECT COUNT(dpl) > 0 FROM DeliveryPartnerLocation dpl WHERE dpl.partnerId = :partnerId " +
           "AND dpl.recordedAt >= :since")
    boolean hasRecentLocationUpdate(@Param("partnerId") Long partnerId, @Param("since") LocalDateTime since);

    /**
     * Get locations for a partner during active delivery
     */
    @Query("SELECT dpl FROM DeliveryPartnerLocation dpl WHERE dpl.partnerId = :partnerId " +
           "AND dpl.assignmentId = :assignmentId AND dpl.orderStatus IN :statuses " +
           "ORDER BY dpl.recordedAt ASC")
    List<DeliveryPartnerLocation> findDeliveryTrackingLocations(
        @Param("partnerId") Long partnerId,
        @Param("assignmentId") Long assignmentId,
        @Param("statuses") List<String> statuses
    );
}