package com.shopmanagement.product.repository;

import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.shop.entity.Shop;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShopProductRepository extends JpaRepository<ShopProduct, Long>, JpaSpecificationExecutor<ShopProduct> {

    // Basic shop-product queries
    List<ShopProduct> findByShop(Shop shop);
    Page<ShopProduct> findByShop(Shop shop, Pageable pageable);
    List<ShopProduct> findByShopId(Long shopId);
    Page<ShopProduct> findByShopId(Long shopId, Pageable pageable);

    // Product availability and status
    List<ShopProduct> findByShopAndStatus(Shop shop, ShopProduct.ShopProductStatus status);
    Page<ShopProduct> findByShopAndStatus(Shop shop, ShopProduct.ShopProductStatus status, Pageable pageable);
    
    List<ShopProduct> findByShopAndIsAvailableTrue(Shop shop);
    Page<ShopProduct> findByShopAndIsAvailableTrue(Shop shop, Pageable pageable);

    // Master product relationships
    Optional<ShopProduct> findByShopAndMasterProduct(Shop shop, MasterProduct masterProduct);
    Optional<ShopProduct> findByShopIdAndMasterProductId(Long shopId, Long masterProductId);
    
    List<ShopProduct> findByMasterProduct(MasterProduct masterProduct);
    Page<ShopProduct> findByMasterProduct(MasterProduct masterProduct, Pageable pageable);

    // Featured products
    List<ShopProduct> findByShopAndIsFeaturedTrue(Shop shop);
    
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop.id = :shopId AND sp.isFeatured = true AND sp.isAvailable = true ORDER BY sp.displayOrder")
    List<ShopProduct> findFeaturedProductsByShop(@Param("shopId") Long shopId);

    // Inventory queries
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND sp.stockQuantity <= sp.minStockLevel AND sp.trackInventory = true")
    List<ShopProduct> findLowStockProducts(@Param("shop") Shop shop);

    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND sp.stockQuantity = 0 AND sp.trackInventory = true")
    List<ShopProduct> findOutOfStockProducts(@Param("shop") Shop shop);

    // Price range queries
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND sp.price BETWEEN :minPrice AND :maxPrice AND sp.isAvailable = true")
    Page<ShopProduct> findByShopAndPriceRange(
            @Param("shop") Shop shop,
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice,
            Pageable pageable);

    // Search within shop products
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND " +
           "(LOWER(COALESCE(sp.customName, sp.masterProduct.name)) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(COALESCE(sp.customDescription, sp.masterProduct.description)) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(sp.masterProduct.sku) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(sp.masterProduct.brand) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<ShopProduct> searchProductsInShop(@Param("shop") Shop shop, @Param("search") String search, Pageable pageable);

    // Category-based queries through master product
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND sp.masterProduct.category.id = :categoryId AND sp.isAvailable = true")
    Page<ShopProduct> findByShopAndCategory(@Param("shop") Shop shop, @Param("categoryId") Long categoryId, Pageable pageable);

    // Brand-based queries through master product
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop AND LOWER(sp.masterProduct.brand) = LOWER(:brand) AND sp.isAvailable = true")
    Page<ShopProduct> findByShopAndBrand(@Param("shop") Shop shop, @Param("brand") String brand, Pageable pageable);

    // Load with relationships - Split into separate queries to avoid MultipleBagFetchException
    @Query("SELECT DISTINCT sp FROM ShopProduct sp LEFT JOIN FETCH sp.shopImages LEFT JOIN FETCH sp.masterProduct WHERE sp.id IN :ids")
    List<ShopProduct> findAllWithShopImagesAndMasterProduct(@Param("ids") List<Long> ids);

    @Query("SELECT DISTINCT sp FROM ShopProduct sp LEFT JOIN FETCH sp.masterProduct LEFT JOIN FETCH sp.masterProduct.images WHERE sp.id IN :ids")
    List<ShopProduct> findAllWithMasterProductImages(@Param("ids") List<Long> ids);

    // Statistics and analytics
    @Query("SELECT COUNT(sp) FROM ShopProduct sp WHERE sp.shop = :shop AND sp.status = :status")
    long countByShopAndStatus(@Param("shop") Shop shop, @Param("status") ShopProduct.ShopProductStatus status);

    @Query("SELECT COUNT(sp) FROM ShopProduct sp WHERE sp.shop = :shop")
    long countByShop(@Param("shop") Shop shop);
    
    @Query("SELECT COUNT(sp) FROM ShopProduct sp WHERE sp.shop = :shop AND sp.isAvailable = true")
    long countAvailableProductsByShop(@Param("shop") Shop shop);

    @Query("SELECT sp.masterProduct.category.name, COUNT(sp) FROM ShopProduct sp " +
           "WHERE sp.shop = :shop AND sp.isAvailable = true " +
           "GROUP BY sp.masterProduct.category " +
           "ORDER BY COUNT(sp) DESC")
    List<Object[]> getProductCountByCategoryForShop(@Param("shop") Shop shop);

    // Pricing analytics
    @Query("SELECT AVG(sp.price) FROM ShopProduct sp WHERE sp.shop = :shop AND sp.isAvailable = true")
    BigDecimal getAveragePriceForShop(@Param("shop") Shop shop);

    @Query("SELECT MIN(sp.price), MAX(sp.price) FROM ShopProduct sp WHERE sp.shop = :shop AND sp.isAvailable = true")
    Object[] getPriceRangeForShop(@Param("shop") Shop shop);

    // Duplicate prevention
    boolean existsByShopAndMasterProduct(Shop shop, MasterProduct masterProduct);
    boolean existsByShopIdAndMasterProductId(Long shopId, Long masterProductId);

    // Cross-shop product queries (for comparing prices across shops)
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.masterProduct = :masterProduct AND sp.isAvailable = true ORDER BY sp.price")
    List<ShopProduct> findByMasterProductOrderByPrice(@Param("masterProduct") MasterProduct masterProduct);

    // Recently added products
    @Query("SELECT sp FROM ShopProduct sp WHERE sp.shop = :shop ORDER BY sp.createdAt DESC")
    Page<ShopProduct> findRecentlyAddedByShop(@Param("shop") Shop shop, Pageable pageable);

    // Data fix methods
    @Modifying
    @Transactional
    @Query("UPDATE ShopProduct sp SET sp.trackInventory = true WHERE sp.trackInventory IS NULL")
    int updateNullTrackInventory();
}