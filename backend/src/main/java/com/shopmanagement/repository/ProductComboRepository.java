package com.shopmanagement.repository;

import com.shopmanagement.entity.ProductCombo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductComboRepository extends JpaRepository<ProductCombo, Long> {

    // Find all combos for a shop
    Page<ProductCombo> findByShopId(Long shopId, Pageable pageable);

    // Find active combos for a shop
    Page<ProductCombo> findByShopIdAndIsActive(Long shopId, Boolean isActive, Pageable pageable);

    // Find combo by ID and shop ID
    Optional<ProductCombo> findByIdAndShopId(Long id, Long shopId);

    // Find currently active combos for a shop (within date range and active)
    @Query("SELECT c FROM ProductCombo c WHERE c.shop.id = :shopId " +
           "AND c.isActive = true " +
           "AND c.startDate <= :today " +
           "AND c.endDate >= :today " +
           "ORDER BY c.displayOrder ASC, c.createdAt DESC")
    List<ProductCombo> findActiveCombosByShopId(@Param("shopId") Long shopId, @Param("today") LocalDate today);

    // Find all active combos for customer view
    @Query("SELECT c FROM ProductCombo c WHERE c.shop.id = :shopId " +
           "AND c.isActive = true " +
           "AND c.startDate <= :today " +
           "AND c.endDate >= :today " +
           "ORDER BY c.displayOrder ASC")
    List<ProductCombo> findActiveCombosForCustomer(@Param("shopId") Long shopId, @Param("today") LocalDate today);

    // Count active combos for a shop
    @Query("SELECT COUNT(c) FROM ProductCombo c WHERE c.shop.id = :shopId " +
           "AND c.isActive = true " +
           "AND c.startDate <= :today " +
           "AND c.endDate >= :today")
    Long countActiveCombos(@Param("shopId") Long shopId, @Param("today") LocalDate today);

    // Find expired combos
    @Query("SELECT c FROM ProductCombo c WHERE c.shop.id = :shopId " +
           "AND c.endDate < :today")
    List<ProductCombo> findExpiredCombos(@Param("shopId") Long shopId, @Param("today") LocalDate today);

    // Find scheduled combos (not yet started)
    @Query("SELECT c FROM ProductCombo c WHERE c.shop.id = :shopId " +
           "AND c.startDate > :today " +
           "AND c.isActive = true")
    List<ProductCombo> findScheduledCombos(@Param("shopId") Long shopId, @Param("today") LocalDate today);

    // Check if combo name exists for shop
    boolean existsByShopIdAndNameIgnoreCase(Long shopId, String name);

    // Check if combo name exists for shop (excluding current combo)
    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM ProductCombo c " +
           "WHERE c.shop.id = :shopId AND LOWER(c.name) = LOWER(:name) AND c.id != :excludeId")
    boolean existsByShopIdAndNameIgnoreCaseAndIdNot(@Param("shopId") Long shopId,
                                                     @Param("name") String name,
                                                     @Param("excludeId") Long excludeId);
}
