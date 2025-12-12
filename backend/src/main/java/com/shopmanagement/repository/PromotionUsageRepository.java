package com.shopmanagement.repository;

import com.shopmanagement.entity.PromotionUsage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionUsageRepository extends JpaRepository<PromotionUsage, Long> {

    /**
     * Count how many times a customer has used a specific promotion
     */
    @Query("SELECT COUNT(pu) FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId AND pu.customer.id = :customerId")
    Long countByPromotionIdAndCustomerId(@Param("promotionId") Long promotionId, @Param("customerId") Long customerId);

    /**
     * Count how many times a device has used a specific promotion
     * (For guest users or additional device tracking)
     */
    @Query("SELECT COUNT(pu) FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId AND pu.deviceUuid = :deviceUuid")
    Long countByPromotionIdAndDeviceUuid(@Param("promotionId") Long promotionId, @Param("deviceUuid") String deviceUuid);

    /**
     * Count by phone number (for additional validation)
     */
    @Query("SELECT COUNT(pu) FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId AND pu.customerPhone = :phone")
    Long countByPromotionIdAndPhone(@Param("promotionId") Long promotionId, @Param("phone") String phone);

    /**
     * Check if promotion was used by customer ID OR device UUID OR phone
     * (Any match means the promotion was already used)
     */
    @Query("SELECT COUNT(pu) FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId " +
           "AND (pu.customer.id = :customerId OR pu.deviceUuid = :deviceUuid OR pu.customerPhone = :phone)")
    Long countByPromotionAndAnyIdentifier(@Param("promotionId") Long promotionId,
                                          @Param("customerId") Long customerId,
                                          @Param("deviceUuid") String deviceUuid,
                                          @Param("phone") String phone);

    /**
     * Get all usages by a customer
     */
    @Query("SELECT pu FROM PromotionUsage pu WHERE pu.customer.id = :customerId ORDER BY pu.usedAt DESC")
    List<PromotionUsage> findByCustomerId(@Param("customerId") Long customerId);

    /**
     * Get all usages of a specific promotion
     */
    @Query("SELECT pu FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId ORDER BY pu.usedAt DESC")
    List<PromotionUsage> findByPromotionId(@Param("promotionId") Long promotionId);

    /**
     * Get all usages of a specific promotion with pagination
     */
    @Query("SELECT pu FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId")
    Page<PromotionUsage> findByPromotionId(@Param("promotionId") Long promotionId, Pageable pageable);

    /**
     * Check if this is customer's first order (for first-time-only promotions)
     */
    @Query("SELECT CASE WHEN COUNT(pu) = 0 THEN true ELSE false END " +
           "FROM PromotionUsage pu WHERE pu.customer.id = :customerId")
    Boolean isFirstTimeCustomer(@Param("customerId") Long customerId);

    /**
     * Check if a first-time-only promotion was already used by customer ID, device UUID, or phone
     * This prevents users from re-using first-time-only promos with different accounts
     */
    @Query("SELECT CASE WHEN COUNT(pu) > 0 THEN true ELSE false END " +
           "FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId " +
           "AND ((:customerId IS NOT NULL AND pu.customer.id = :customerId) " +
           "OR (:deviceUuid IS NOT NULL AND pu.deviceUuid = :deviceUuid) " +
           "OR (:phone IS NOT NULL AND pu.customerPhone = :phone))")
    Boolean hasUsedPromotion(@Param("promotionId") Long promotionId,
                             @Param("customerId") Long customerId,
                             @Param("deviceUuid") String deviceUuid,
                             @Param("phone") String phone);

    /**
     * Get usage history for a specific customer and promotion
     */
    @Query("SELECT pu FROM PromotionUsage pu WHERE pu.promotion.id = :promotionId " +
           "AND pu.customer.id = :customerId ORDER BY pu.usedAt DESC")
    List<PromotionUsage> findByPromotionIdAndCustomerId(@Param("promotionId") Long promotionId,
                                                         @Param("customerId") Long customerId);

    /**
     * Check if promotion is used in any active/pending order by customer ID, device UUID, or phone
     * Active orders are those NOT in DELIVERED, COMPLETED, CANCELLED, or REFUNDED status
     */
    @Query("SELECT CASE WHEN COUNT(pu) > 0 THEN true ELSE false END " +
           "FROM PromotionUsage pu " +
           "WHERE pu.promotion.id = :promotionId " +
           "AND ((:customerId IS NOT NULL AND pu.customer.id = :customerId) " +
           "OR (:deviceUuid IS NOT NULL AND pu.deviceUuid = :deviceUuid) " +
           "OR (:phone IS NOT NULL AND pu.customerPhone = :phone)) " +
           "AND pu.order.status NOT IN ('DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED')")
    Boolean hasActivePendingOrderWithPromotion(@Param("promotionId") Long promotionId,
                                                @Param("customerId") Long customerId,
                                                @Param("deviceUuid") String deviceUuid,
                                                @Param("phone") String phone);
}
