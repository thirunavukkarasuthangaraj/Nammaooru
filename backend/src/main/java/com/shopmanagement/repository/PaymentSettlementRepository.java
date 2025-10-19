package com.shopmanagement.repository;

import com.shopmanagement.entity.PaymentSettlement;
import com.shopmanagement.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentSettlementRepository extends JpaRepository<PaymentSettlement, Long> {

    // Find all settlements for a specific delivery partner
    List<PaymentSettlement> findByDeliveryPartnerOrderByCreatedAtDesc(User deliveryPartner);

    // Find all settlements for a specific delivery partner by ID
    List<PaymentSettlement> findByDeliveryPartnerIdOrderByCreatedAtDesc(Long partnerId);

    // Find settlements within a date range
    @Query("SELECT ps FROM PaymentSettlement ps WHERE ps.settlementDate BETWEEN :startDate AND :endDate ORDER BY ps.settlementDate DESC")
    List<PaymentSettlement> findSettlementsBetweenDates(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );

    // Find settlements by status
    List<PaymentSettlement> findByStatusOrderByCreatedAtDesc(PaymentSettlement.SettlementStatus status);

    // Find settlements by payment method
    List<PaymentSettlement> findByPaymentMethodOrderByCreatedAtDesc(PaymentSettlement.PaymentMethod paymentMethod);

    // Get total settled amount for a partner
    @Query("SELECT COALESCE(SUM(ps.netAmount), 0) FROM PaymentSettlement ps WHERE ps.deliveryPartner.id = :partnerId AND ps.status = 'COMPLETED'")
    Long getTotalSettledAmountForPartner(@Param("partnerId") Long partnerId);

    // Count settlements for a partner
    Long countByDeliveryPartnerId(Long partnerId);
}
