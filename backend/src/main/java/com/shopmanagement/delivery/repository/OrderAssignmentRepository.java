package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.OrderAssignment;
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

    List<OrderAssignment> findByOrderId(Long orderId);
    
    List<OrderAssignment> findByDeliveryPartnerId(Long partnerId);
    
    Page<OrderAssignment> findByDeliveryPartnerId(Long partnerId, Pageable pageable);
    
    List<OrderAssignment> findByStatus(OrderAssignment.AssignmentStatus status);
    
    Optional<OrderAssignment> findByOrderIdAndStatus(Long orderId, OrderAssignment.AssignmentStatus status);
    
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = :status")
    List<OrderAssignment> findByPartnerIdAndStatus(
            @Param("partnerId") Long partnerId, 
            @Param("status") OrderAssignment.AssignmentStatus status
    );
    
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status IN :statuses")
    List<OrderAssignment> findByPartnerIdAndStatusIn(
            @Param("partnerId") Long partnerId, 
            @Param("statuses") List<OrderAssignment.AssignmentStatus> statuses
    );
    
    @Query("SELECT COUNT(oa) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.status = 'DELIVERED'")
    Long countCompletedDeliveriesByPartner(@Param("partnerId") Long partnerId);
    
    @Query("SELECT COUNT(oa) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId")
    Long countTotalAssignmentsByPartner(@Param("partnerId") Long partnerId);
    
    @Query("""
        SELECT oa FROM OrderAssignment oa 
        WHERE oa.assignedAt BETWEEN :startDate AND :endDate 
        AND oa.status = :status
    """)
    List<OrderAssignment> findByDateRangeAndStatus(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate,
            @Param("status") OrderAssignment.AssignmentStatus status
    );
    
    @Query("""
        SELECT oa FROM OrderAssignment oa 
        WHERE oa.deliveryPartner.id = :partnerId 
        AND oa.assignedAt BETWEEN :startDate AND :endDate
    """)
    List<OrderAssignment> findByPartnerAndDateRange(
            @Param("partnerId") Long partnerId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );
    
    @Query("SELECT oa FROM OrderAssignment oa WHERE oa.status = 'ASSIGNED' AND oa.assignedAt < :timeoutDate")
    List<OrderAssignment> findExpiredAssignments(@Param("timeoutDate") LocalDateTime timeoutDate);
    
    @Query("""
        SELECT oa FROM OrderAssignment oa 
        WHERE oa.status IN ('ACCEPTED', 'PICKED_UP', 'IN_TRANSIT') 
        AND oa.deliveryPartner.id = :partnerId
    """)
    List<OrderAssignment> findActiveAssignmentsByPartner(@Param("partnerId") Long partnerId);
    
    @Query("SELECT AVG(oa.customerRating) FROM OrderAssignment oa WHERE oa.deliveryPartner.id = :partnerId AND oa.customerRating IS NOT NULL")
    Double getAverageRatingForPartner(@Param("partnerId") Long partnerId);
}