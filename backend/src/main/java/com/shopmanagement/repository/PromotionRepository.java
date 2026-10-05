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
     * Find active promotions for a specific shop
     */
    @Query("SELECT p FROM Promotion p WHERE p.status = 'ACTIVE' " +
           "AND p.startDate <= :now AND p.endDate >= :now " +
           "AND (p.usageLimit IS NULL OR p.usedCount < p.usageLimit) " +
           "AND (p.shopId = :shopId OR p.shopId IS NULL)")
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
     * Banner videos in one review state. Oldest submission first, so the queue
     * is answered in the order it arrived.
     *
     * Kept separate from findAllWithVideo() rather than using a
     * "(:status IS NULL OR ...)" query: Hibernate can't infer the type of a
     * null enum parameter, so the "all" case has to be its own query.
     */
    @Query("SELECT p FROM Promotion p WHERE p.videoUrl IS NOT NULL " +
           "AND p.videoStatus = :status " +
           "ORDER BY p.videoSubmittedAt ASC")
    List<Promotion> findByVideoStatus(@Param("status") Promotion.VideoStatus status);

    /** Every promotion that has a banner video, whatever its review state. */
    @Query("SELECT p FROM Promotion p WHERE p.videoUrl IS NOT NULL " +
           "ORDER BY p.videoSubmittedAt ASC")
    List<Promotion> findAllWithVideo();
}