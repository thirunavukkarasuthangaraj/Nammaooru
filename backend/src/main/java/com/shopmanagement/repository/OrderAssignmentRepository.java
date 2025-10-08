package com.shopmanagement.repository;

import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.OrderAssignment.AssignmentStatus;
import com.shopmanagement.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderAssignmentRepository extends JpaRepository<OrderAssignment, Long> {

    // Find assignments by delivery partner
    List<OrderAssignment> findByDeliveryPartner(User deliveryPartner);
    Page<OrderAssignment> findByDeliveryPartner(User deliveryPartner, Pageable pageable);
    Long countByDeliveryPartner(User deliveryPartner);

    // Count assignments by delivery partner created after a specific time (for fair distribution)
    Long countByDeliveryPartnerAndCreatedAtAfter(User deliveryPartner, LocalDateTime createdAt);

    // Find assignments by delivery partner and status
    List<OrderAssignment> findByDeliveryPartnerAndStatus(User deliveryPartner, AssignmentStatus status);
    Page<OrderAssignment> findByDeliveryPartnerAndStatus(User deliveryPartner, AssignmentStatus status, Pageable pageable);

    // Find assignments by delivery partner and multiple statuses
    List<OrderAssignment> findByDeliveryPartnerAndStatusIn(User deliveryPartner, List<AssignmentStatus> statuses);

    // Find assignments by order
    @Query("SELECT oa FROM OrderAssignment oa JOIN FETCH oa.order o JOIN FETCH o.customer JOIN FETCH o.shop JOIN FETCH oa.deliveryPartner WHERE oa.order.id = :orderId")
    List<OrderAssignment> findByOrderId(@Param("orderId") Long orderId);

    @Query("SELECT oa FROM OrderAssignment oa JOIN FETCH oa.order o JOIN FETCH o.customer JOIN FETCH o.shop JOIN FETCH oa.deliveryPartner WHERE oa.order.id = :orderId AND oa.status = :status")
    Optional<OrderAssignment> findByOrderIdAndStatus(@Param("orderId") Long orderId, @Param("status") AssignmentStatus status);

    // Find active assignment for an order
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.order.id = :orderId AND oa.status IN :activeStatuses ORDER BY oa.createdAt DESC")
    Optional<OrderAssignment> findActiveAssignmentByOrderId(@Param("orderId") Long orderId,
                                                           @Param("activeStatuses") List<AssignmentStatus> activeStatuses);

    // Find current assignment for a delivery partner
    @Query("SELECT oa FROM OrderAssignment oa JOIN FETCH oa.order o JOIN FETCH o.customer JOIN FETCH o.shop JOIN FETCH oa.deliveryPartner WHERE oa.deliveryPartner.id = :partnerId AND oa.status IN :activeStatuses ORDER BY oa.createdAt DESC")
    Optional<OrderAssignment> findCurrentAssignmentByPartnerId(@Param("partnerId") Long partnerId,
                                                              @Param("activeStatuses") List<AssignmentStatus> activeStatuses);

    // Find assignments by status
    List<OrderAssignment> findByStatus(AssignmentStatus status);
    Page<OrderAssignment> findByStatus(AssignmentStatus status, Pageable pageable);

    // Find pending assignments for a delivery partner
    @Query("SELECT oa FROM OrderAssignment oa JOIN FETCH oa.order o JOIN FETCH o.customer JOIN FETCH o.shop JOIN FETCH oa.deliveryPartner WHERE oa.deliveryPartner.id = :partnerId AND oa.status = 'ASSIGNED'")
    List<OrderAssignment> findPendingAssignmentsByPartnerId(@Param("partnerId") Long partnerId);

    // Find assignments in date range
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.assignedAt BETWEEN :startDate AND :endDate")
    List<OrderAssignment> findAssignmentsBetween(@Param("startDate") LocalDateTime startDate,
                                               @Param("endDate") LocalDateTime endDate);

    // Count assignments by partner and status
    @Query("SELECT COUNT(oa) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = :status")
    Long countByPartnerIdAndStatus(@Param("partnerId") Long partnerId, @Param("status") AssignmentStatus status);

    // Partner performance queries
    @Query("SELECT COUNT(oa) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = 'COMPLETED'")
    Long countCompletedAssignmentsByPartnerId(@Param("partnerId") Long partnerId);

    @Query("SELECT COUNT(oa) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = 'REJECTED'")
    Long countRejectedAssignmentsByPartnerId(@Param("partnerId") Long partnerId);

    @Query("SELECT AVG(oa.customerRating) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.customerRating IS NOT NULL")
    Double getAverageRatingByPartnerId(@Param("partnerId") Long partnerId);

    // Get assignments requiring attention (assigned but not accepted within time limit)
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.status = 'ASSIGNED' AND oa.assignedAt < :cutoffTime")
    List<OrderAssignment> findStaleAssignments(@Param("cutoffTime") LocalDateTime cutoffTime);

    // Find available delivery partners for assignment
    @Query("SELECT u FROM User u WHERE u.role = 'DELIVERY_PARTNER' AND u.isOnline = true AND u.isAvailable = true " +
           "AND u.rideStatus = 'AVAILABLE' AND u.id NOT IN " +
           "(SELECT oa.deliveryPartner.id FROM OrderAssignment oa WHERE oa.status IN :activeStatuses)")
    List<User> findAvailableDeliveryPartners(@Param("activeStatuses") List<AssignmentStatus> activeStatuses);

    // Find nearby delivery partners (for future location-based assignment)
    @Query("SELECT u FROM User u WHERE u.role = 'DELIVERY_PARTNER' AND u.isOnline = true AND u.isAvailable = true " +
           "AND u.currentLatitude IS NOT NULL AND u.currentLongitude IS NOT NULL " +
           "AND u.id NOT IN (SELECT oa.deliveryPartner.id FROM OrderAssignment oa WHERE oa.status IN :activeStatuses)")
    List<User> findNearbyAvailableDeliveryPartners(@Param("activeStatuses") List<AssignmentStatus> activeStatuses);

    // Analytics queries
    @Query("SELECT oa.status, COUNT(oa) FROM OrderAssignment oa GROUP BY oa.status")
    List<Object[]> getAssignmentCountByStatus();

    @Query("SELECT DATE(oa.assignedAt), COUNT(oa) FROM OrderAssignment oa WHERE oa.assignedAt >= :startDate GROUP BY DATE(oa.assignedAt)")
    List<Object[]> getDailyAssignmentCounts(@Param("startDate") LocalDateTime startDate);

    // Get partner earnings data
    @Query("SELECT SUM(oa.partnerCommission) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = 'COMPLETED'")
    Double getTotalEarningsByPartnerId(@Param("partnerId") Long partnerId);

    @Query("SELECT SUM(oa.partnerCommission) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId " +
           "AND oa.status = 'COMPLETED' AND oa.deliveryCompletedAt BETWEEN :startDate AND :endDate")
    Double getEarningsByPartnerIdBetween(@Param("partnerId") Long partnerId,
                                       @Param("startDate") LocalDateTime startDate,
                                       @Param("endDate") LocalDateTime endDate);
}