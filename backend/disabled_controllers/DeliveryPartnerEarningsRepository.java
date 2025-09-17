package com.shopmanagement.repository;

import com.shopmanagement.entity.DeliveryPartnerEarnings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerEarningsRepository extends JpaRepository<DeliveryPartnerEarnings, Long> {

    /**
     * Find earnings by delivery partner ID and date range
     */
    @Query("SELECT e FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.earningDate BETWEEN :startDate AND :endDate ORDER BY e.earningDate DESC")
    List<DeliveryPartnerEarnings> findByPartnerIdAndDateRange(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get total earnings for a partner within date range
     */
    @Query("SELECT COALESCE(SUM(e.finalEarning), 0) FROM DeliveryPartnerEarnings e " +
           "WHERE e.deliveryPartner.id = :partnerId AND e.earningDate BETWEEN :startDate AND :endDate")
    BigDecimal getTotalEarningsByPartnerAndDateRange(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get total commission earned for a partner within date range
     */
    @Query("SELECT COALESCE(SUM(e.commissionAmount), 0) FROM DeliveryPartnerEarnings e " +
           "WHERE e.deliveryPartner.id = :partnerId AND e.earningDate BETWEEN :startDate AND :endDate")
    BigDecimal getTotalCommissionByPartnerAndDateRange(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get daily earnings summary for a partner
     */
    @Query("SELECT e.earningDate, COALESCE(SUM(e.finalEarning), 0), COUNT(e) " +
           "FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.earningDate BETWEEN :startDate AND :endDate " +
           "GROUP BY e.earningDate ORDER BY e.earningDate DESC")
    List<Object[]> getDailyEarningsSummary(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get earnings by order ID
     */
    Optional<DeliveryPartnerEarnings> findByOrderId(Long orderId);

    /**
     * Get pending payments for a partner
     */
    @Query("SELECT e FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.paymentStatus = 'PENDING' ORDER BY e.earningDate ASC")
    List<DeliveryPartnerEarnings> getPendingPayments(@Param("partnerId") Long partnerId);

    /**
     * Get total pending amount for a partner
     */
    @Query("SELECT COALESCE(SUM(e.finalEarning), 0) FROM DeliveryPartnerEarnings e " +
           "WHERE e.deliveryPartner.id = :partnerId AND e.paymentStatus = 'PENDING'")
    BigDecimal getTotalPendingAmount(@Param("partnerId") Long partnerId);

    /**
     * Get performance metrics aggregation
     */
    @Query("SELECT AVG(e.customerRating), AVG(e.deliveryTimeMinutes), AVG(e.distanceKm), COUNT(e) " +
           "FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.earningDate BETWEEN :startDate AND :endDate")
    List<Object[]> getPerformanceMetrics(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get top performing partners by earnings
     */
    @Query("SELECT e.deliveryPartner.id, e.deliveryPartner.username, COALESCE(SUM(e.finalEarning), 0), COUNT(e) " +
           "FROM DeliveryPartnerEarnings e WHERE e.earningDate BETWEEN :startDate AND :endDate " +
           "GROUP BY e.deliveryPartner.id, e.deliveryPartner.username " +
           "ORDER BY SUM(e.finalEarning) DESC")
    List<Object[]> getTopPerformers(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get monthly earnings summary
     */
    @Query("SELECT YEAR(e.earningDate), MONTH(e.earningDate), " +
           "COALESCE(SUM(e.finalEarning), 0), COALESCE(SUM(e.commissionAmount), 0), " +
           "COALESCE(SUM(e.bonusAmount), 0), COALESCE(SUM(e.penaltyAmount), 0), COUNT(e) " +
           "FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.earningDate BETWEEN :startDate AND :endDate " +
           "GROUP BY YEAR(e.earningDate), MONTH(e.earningDate) " +
           "ORDER BY YEAR(e.earningDate) DESC, MONTH(e.earningDate) DESC")
    List<Object[]> getMonthlyEarningsSummary(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Get weekly earnings summary
     */
    @Query("SELECT YEAR(e.earningDate), WEEK(e.earningDate), " +
           "COALESCE(SUM(e.finalEarning), 0), COUNT(e) " +
           "FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId " +
           "AND e.earningDate BETWEEN :startDate AND :endDate " +
           "GROUP BY YEAR(e.earningDate), WEEK(e.earningDate) " +
           "ORDER BY YEAR(e.earningDate) DESC, WEEK(e.earningDate) DESC")
    List<Object[]> getWeeklyEarningsSummary(
        @Param("partnerId") Long partnerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Find earnings by partner and payment status
     */
    List<DeliveryPartnerEarnings> findByDeliveryPartnerIdAndPaymentStatusOrderByEarningDateDesc(
        Long partnerId,
        DeliveryPartnerEarnings.PaymentStatus paymentStatus
    );

    /**
     * Get earnings statistics for dashboard
     */
    @Query("SELECT " +
           "COALESCE(SUM(CASE WHEN e.earningDate = CURRENT_DATE THEN e.finalEarning ELSE 0 END), 0) as todayEarnings, " +
           "COALESCE(SUM(CASE WHEN e.earningDate >= :weekStart THEN e.finalEarning ELSE 0 END), 0) as weekEarnings, " +
           "COALESCE(SUM(CASE WHEN YEAR(e.earningDate) = YEAR(CURRENT_DATE) AND MONTH(e.earningDate) = MONTH(CURRENT_DATE) THEN e.finalEarning ELSE 0 END), 0) as monthEarnings, " +
           "COALESCE(SUM(e.finalEarning), 0) as totalEarnings, " +
           "COUNT(e) as totalDeliveries " +
           "FROM DeliveryPartnerEarnings e WHERE e.deliveryPartner.id = :partnerId")
    List<Object[]> getEarningsStatistics(
        @Param("partnerId") Long partnerId,
        @Param("weekStart") LocalDate weekStart
    );
}