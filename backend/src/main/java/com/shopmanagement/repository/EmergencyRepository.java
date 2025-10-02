package com.shopmanagement.repository;

import com.shopmanagement.entity.Emergency;
import com.shopmanagement.entity.Emergency.EmergencyStatus;
import com.shopmanagement.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmergencyRepository extends JpaRepository<Emergency, Long> {

    // Find by emergency ID
    Optional<Emergency> findByEmergencyId(String emergencyId);

    // Find all emergencies for a specific partner
    List<Emergency> findByPartnerIdOrderByCreatedAtDesc(Long partnerId);

    // Find active emergencies for a partner
    List<Emergency> findByPartnerIdAndStatus(Long partnerId, EmergencyStatus status);

    // Find all active emergencies
    List<Emergency> findByStatus(EmergencyStatus status);

    // Find all emergencies with multiple statuses
    List<Emergency> findByStatusIn(List<EmergencyStatus> statuses);

    // Find emergencies by partner and date range
    @Query("SELECT e FROM Emergency e WHERE e.partner.id = :partnerId " +
           "AND e.createdAt BETWEEN :startDate AND :endDate " +
           "ORDER BY e.createdAt DESC")
    List<Emergency> findByPartnerAndDateRange(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );

    // Count active emergencies
    Long countByStatus(EmergencyStatus status);

    // Count partner's emergencies by status
    Long countByPartnerIdAndStatus(Long partnerId, EmergencyStatus status);

    // Find recent emergencies
    @Query("SELECT e FROM Emergency e WHERE e.createdAt >= :since ORDER BY e.createdAt DESC")
    List<Emergency> findRecentEmergencies(@Param("since") LocalDateTime since);

    // Find emergencies that need response (active or in progress)
    @Query("SELECT e FROM Emergency e WHERE e.status IN ('ACTIVE', 'IN_PROGRESS') " +
           "ORDER BY e.severity DESC, e.createdAt ASC")
    List<Emergency> findEmergenciesNeedingResponse();

    // Check if partner has active emergency
    Boolean existsByPartnerIdAndStatus(Long partnerId, EmergencyStatus status);
}