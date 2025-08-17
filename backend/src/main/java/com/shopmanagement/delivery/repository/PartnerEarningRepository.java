package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.PartnerEarning;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface PartnerEarningRepository extends JpaRepository<PartnerEarning, Long> {

    List<PartnerEarning> findByDeliveryPartnerId(Long partnerId);
    
    Page<PartnerEarning> findByDeliveryPartnerId(Long partnerId, Pageable pageable);
    
    List<PartnerEarning> findByPaymentStatus(PartnerEarning.PaymentStatus paymentStatus);
    
    @Query("SELECT pe FROM PartnerEarning pe WHERE pe.deliveryPartner.id = :partnerId AND pe.earningDate = :date")
    List<PartnerEarning> findByPartnerAndDate(@Param("partnerId") Long partnerId, @Param("date") LocalDate date);
    
    @Query("""
        SELECT pe FROM PartnerEarning pe 
        WHERE pe.deliveryPartner.id = :partnerId 
        AND pe.earningDate BETWEEN :startDate AND :endDate
    """)
    List<PartnerEarning> findByPartnerAndDateRange(
            @Param("partnerId") Long partnerId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
    
    @Query("SELECT SUM(pe.totalAmount) FROM PartnerEarning pe WHERE pe.deliveryPartner.id = :partnerId")
    BigDecimal getTotalEarningsByPartner(@Param("partnerId") Long partnerId);
    
    @Query("""
        SELECT SUM(pe.totalAmount) FROM PartnerEarning pe 
        WHERE pe.deliveryPartner.id = :partnerId 
        AND pe.earningDate BETWEEN :startDate AND :endDate
    """)
    BigDecimal getTotalEarningsByPartnerAndDateRange(
            @Param("partnerId") Long partnerId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
    
    @Query("""
        SELECT SUM(pe.totalAmount) FROM PartnerEarning pe 
        WHERE pe.deliveryPartner.id = :partnerId 
        AND pe.paymentStatus = :paymentStatus
    """)
    BigDecimal getTotalEarningsByPartnerAndPaymentStatus(
            @Param("partnerId") Long partnerId,
            @Param("paymentStatus") PartnerEarning.PaymentStatus paymentStatus
    );
    
    @Query("SELECT AVG(pe.totalAmount) FROM PartnerEarning pe WHERE pe.deliveryPartner.id = :partnerId")
    BigDecimal getAverageEarningsByPartner(@Param("partnerId") Long partnerId);
    
    @Query("""
        SELECT pe.earningDate, SUM(pe.totalAmount) FROM PartnerEarning pe 
        WHERE pe.deliveryPartner.id = :partnerId 
        AND pe.earningDate BETWEEN :startDate AND :endDate 
        GROUP BY pe.earningDate 
        ORDER BY pe.earningDate
    """)
    List<Object[]> getDailyEarningsByPartner(
            @Param("partnerId") Long partnerId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
    
    @Query("""
        SELECT COUNT(pe) FROM PartnerEarning pe 
        WHERE pe.paymentStatus = 'PENDING' 
        AND pe.earningDate <= :cutoffDate
    """)
    Long countPendingPayments(@Param("cutoffDate") LocalDate cutoffDate);
    
    @Query("""
        SELECT pe FROM PartnerEarning pe 
        WHERE pe.paymentStatus = 'PENDING' 
        AND pe.earningDate <= :cutoffDate 
        ORDER BY pe.earningDate ASC
    """)
    List<PartnerEarning> findPendingPayments(@Param("cutoffDate") LocalDate cutoffDate);
}