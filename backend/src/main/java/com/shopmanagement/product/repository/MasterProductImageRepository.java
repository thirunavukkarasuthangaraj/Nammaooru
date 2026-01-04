package com.shopmanagement.product.repository;

import com.shopmanagement.product.entity.MasterProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MasterProductImageRepository extends JpaRepository<MasterProductImage, Long> {
    
    List<MasterProductImage> findByMasterProductIdOrderBySortOrderAsc(Long masterProductId);
    
    Optional<MasterProductImage> findByMasterProductIdAndIsPrimaryTrue(Long masterProductId);
    
    @Query("SELECT img FROM MasterProductImage img WHERE img.masterProduct.id = :productId AND img.isPrimary = true")
    Optional<MasterProductImage> findPrimaryImageByProductId(@Param("productId") Long productId);
    
    void deleteByMasterProductId(Long masterProductId);

    long countByMasterProductId(Long masterProductId);

    // Find image by product ID and URL (for checking duplicates)
    Optional<MasterProductImage> findByMasterProductIdAndImageUrl(Long masterProductId, String imageUrl);

    // Clear all primary flags for a product (used before setting new primary)
    @org.springframework.data.jpa.repository.Modifying(clearAutomatically = true)
    @org.springframework.transaction.annotation.Transactional
    @Query("UPDATE MasterProductImage img SET img.isPrimary = false WHERE img.masterProduct.id = :productId")
    void clearPrimaryForProduct(@Param("productId") Long productId);
}