package com.shopmanagement.product.repository;

import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.ProductCategory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MasterProductRepository extends JpaRepository<MasterProduct, Long>, JpaSpecificationExecutor<MasterProduct> {

    // Find by basic properties
    Optional<MasterProduct> findBySku(String sku);
    Optional<MasterProduct> findByBarcode(String barcode);
    
    // Status-based queries
    List<MasterProduct> findByStatus(MasterProduct.ProductStatus status);
    Page<MasterProduct> findByStatus(MasterProduct.ProductStatus status, Pageable pageable);
    
    // Category-based queries
    List<MasterProduct> findByCategory(ProductCategory category);
    Page<MasterProduct> findByCategory(ProductCategory category, Pageable pageable);
    Page<MasterProduct> findByCategoryId(Long categoryId, Pageable pageable);
    
    // Brand-based queries
    List<MasterProduct> findByBrand(String brand);
    Page<MasterProduct> findByBrand(String brand, Pageable pageable);
    
    @Query("SELECT DISTINCT p.brand FROM MasterProduct p WHERE p.brand IS NOT NULL ORDER BY p.brand")
    List<String> findAllBrands();

    // Featured products
    List<MasterProduct> findByIsFeaturedTrueAndStatus(MasterProduct.ProductStatus status);
    
    @Query("SELECT p FROM MasterProduct p WHERE p.isFeatured = true AND p.status = 'ACTIVE' ORDER BY p.name")
    List<MasterProduct> findFeaturedProducts();

    // Global products (available to all shops)
    @Query("SELECT p FROM MasterProduct p WHERE p.isGlobal = true AND p.status = 'ACTIVE'")
    Page<MasterProduct> findGlobalProducts(Pageable pageable);

    // Search queries
    @Query("SELECT p FROM MasterProduct p WHERE " +
           "LOWER(p.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(p.sku) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(p.brand) LIKE LOWER(CONCAT('%', :search, '%'))")
    Page<MasterProduct> searchProducts(@Param("search") String search, Pageable pageable);

    // AI Search - Find by status ordered by created date
    @Query("SELECT p FROM MasterProduct p WHERE p.status = :status ORDER BY p.createdAt DESC")
    List<MasterProduct> findByStatusOrderByCreatedAtDesc(@Param("status") MasterProduct.ProductStatus status);

    // Search by tags (for AI search)
    @Query("SELECT p FROM MasterProduct p WHERE " +
           "p.status = :status AND " +
           "LOWER(p.tags) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "ORDER BY p.createdAt DESC")
    Page<MasterProduct> searchByTags(@Param("keyword") String keyword, @Param("status") MasterProduct.ProductStatus status, Pageable pageable);

    // Advanced search with filters
    @Query("SELECT p FROM MasterProduct p WHERE " +
           "(:categoryId IS NULL OR p.category.id = :categoryId) AND " +
           "(:brand IS NULL OR LOWER(p.brand) = LOWER(:brand)) AND " +
           "(:status IS NULL OR p.status = :status) AND " +
           "(:isFeatured IS NULL OR p.isFeatured = :isFeatured) AND " +
           "(:search IS NULL OR " +
           "  LOWER(p.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "  LOWER(p.description) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "  LOWER(p.sku) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<MasterProduct> findWithFilters(
            @Param("categoryId") Long categoryId,
            @Param("brand") String brand,
            @Param("status") MasterProduct.ProductStatus status,
            @Param("isFeatured") Boolean isFeatured,
            @Param("search") String search,
            Pageable pageable);

    // Load products with images
    @Query("SELECT DISTINCT p FROM MasterProduct p LEFT JOIN FETCH p.images WHERE p.id IN :ids")
    List<MasterProduct> findAllWithImages(@Param("ids") List<Long> ids);

    // Validation queries
    boolean existsBySku(String sku);
    boolean existsByBarcode(String barcode);
    boolean existsBySkuAndIdNot(String sku, Long id);
    boolean existsByBarcodeAndIdNot(String barcode, Long id);

    // Statistics
    @Query("SELECT COUNT(p) FROM MasterProduct p WHERE p.status = :status")
    long countByStatus(@Param("status") MasterProduct.ProductStatus status);

    @Query("SELECT p.category.name, COUNT(p) FROM MasterProduct p GROUP BY p.category ORDER BY COUNT(p) DESC")
    List<Object[]> getProductCountByCategory();

    @Query("SELECT p.brand, COUNT(p) FROM MasterProduct p WHERE p.brand IS NOT NULL GROUP BY p.brand ORDER BY COUNT(p) DESC")
    List<Object[]> getProductCountByBrand();

    // Find all products ordered by category sort order, then by product name
    @Query("SELECT p FROM MasterProduct p JOIN p.category c ORDER BY c.sortOrder ASC, p.name ASC")
    Page<MasterProduct> findAllOrderedByCategoryPriority(Pageable pageable);
}