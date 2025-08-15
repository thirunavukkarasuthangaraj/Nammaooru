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
}