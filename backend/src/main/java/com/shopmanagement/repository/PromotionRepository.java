package com.shopmanagement.repository;

import com.shopmanagement.entity.Promotion;
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
public interface PromotionRepository extends JpaRepository<Promotion, Long> {

    /**
     * Find promotion by code (case-insensitive)
     */
    @Query("SELECT p FROM Promotion p WHERE UPPER(p.code) = UPPER(:code)")
    Optional<Promotion> findByCode(@Param("code") String code);

    /**
     * Find all active promotions
     */
    @Query("SELECT p FROM Promotion p WHERE p.status = 'ACTIVE' " +
           "AND p.startDate <= :now AND p.endDate >= :now " +
           "AND (p.usageLimit IS NULL OR p.usedCount < p.usageLimit)")
    List<Promotion> findAllActive(@Param("now") LocalDateTime now);

    /**
     * Active promotions shown INSIDE one shop's page.
     *
     * Two kinds qualify:
     *  - the shop's own promotions, and
     *  - platform-wide PROMO_CODE offers (shopId null) that are public, such as
     *    a WELCOME50 voucher. Checkout already accepts a platform code at any
     *    shop, so hiding it on the shop page only stopped customers finding it.
     *
     * Platform IMAGE_BANNER rows are deliberately excluded: those are the
     * admin's Home artwork, and listing them inside every shop made it look as
     * though the shop itself had made the offer. They stay on the Home carousel
     * (findAllPublicActive).
     */
    @Query("SELECT p FROM Promotion p WHERE p.status = 'ACTIVE' " +
           "AND p.startDate <= :now AND p.endDate >= :now " +
           "AND (p.usageLimit IS NULL OR p.usedCount < p.usageLimit) " +
           "AND (p.shopId = :shopId " +
           "     OR (p.shopId IS NULL AND p.isPublic = true AND p.bannerType = 'PROMO_CODE'))")
    List<Promotion> findActiveByShopId(@Param("shopId") Long shopId, @Param("now") LocalDateTime now);

    /**
     * Find public promotions (visible to all customers)
     */
    @Query("SELECT p FROM Promotion p WHERE p.status = 'ACTIVE' " +
           "AND p.isPublic = true " +
           "AND p.startDate <= :now AND p.endDate >= :now " +
           "AND (p.usageLimit IS NULL OR p.usedCount < p.usageLimit)")
    List<Promotion> findAllPublicActive(@Param("now") LocalDateTime now);

    /**
     * Find all promotions for a specific shop with pagination
     */
    @Query("SELECT p FROM Promotion p WHERE p.shopId = :shopId")
    Page<Promotion> findByShopId(@Param("shopId") Long shopId, Pageable pageable);

    /**
     * Banner assets (image and/or video) in one review state. Oldest
     * submission first, so the queue is answered in the order it arrived.
     *
     * Not written as "(:status IS NULL OR ...)" for the all-states case:
     * Hibernate can't infer the type of a null enum parameter, so "all" has to
     * be its own query - see findAllWithBanner().
     */
    @Query("SELECT p FROM Promotion p " +
           "WHERE p.imageStatus = :status OR p.videoStatus = :status " +
           "ORDER BY COALESCE(p.videoSubmittedAt, p.imageSubmittedAt) ASC")
    List<Promotion> findByBannerStatus(@Param("status") Promotion.ReviewStatus status);

    /** Every promotion carrying banner artwork, whatever its review state. */
    @Query("SELECT p FROM Promotion p " +
           "WHERE p.imageUrl IS NOT NULL OR p.videoUrl IS NOT NULL " +
           "ORDER BY COALESCE(p.videoSubmittedAt, p.imageSubmittedAt) ASC")
    List<Promotion> findAllWithBanner();
}