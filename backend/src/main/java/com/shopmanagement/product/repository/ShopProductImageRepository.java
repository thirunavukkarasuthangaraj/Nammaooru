package com.shopmanagement.product.repository;

import com.shopmanagement.product.entity.ShopProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShopProductImageRepository extends JpaRepository<ShopProductImage, Long> {
    
    List<ShopProductImage> findByShopProductIdOrderBySortOrderAsc(Long shopProductId);
    
    Optional<ShopProductImage> findByShopProductIdAndIsPrimaryTrue(Long shopProductId);
    
    @Query("SELECT img FROM ShopProductImage img WHERE img.shopProduct.id = :productId AND img.isPrimary = true")
    Optional<ShopProductImage> findPrimaryImageByProductId(@Param("productId") Long productId);
    
    void deleteByShopProductId(Long shopProductId);
    
    long countByShopProductId(Long shopProductId);
}