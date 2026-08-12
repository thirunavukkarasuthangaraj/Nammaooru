package com.shopmanagement.repository;

import com.shopmanagement.entity.ShopWhatsAppUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface ShopWhatsAppUsageRepository extends JpaRepository<ShopWhatsAppUsage, Long> {

    long countByShopIdAndSettledFalse(Long shopId);

    long countByShopIdAndSettledFalseAndMessageType(Long shopId, String messageType);

    long countByShopIdAndSettledFalseAndCreatedAtLessThanEqual(Long shopId, LocalDateTime upTo);

    long countByShopIdAndSettledFalseAndMessageTypeAndCreatedAtLessThanEqual(Long shopId, String messageType, LocalDateTime upTo);

    @Modifying
    @Query("UPDATE ShopWhatsAppUsage u SET u.settled = true, u.settledPaymentId = :paymentId " +
           "WHERE u.shopId = :shopId AND u.settled = false AND u.createdAt <= :upTo")
    int settleUpTo(@Param("shopId") Long shopId, @Param("upTo") LocalDateTime upTo, @Param("paymentId") Long paymentId);
}
