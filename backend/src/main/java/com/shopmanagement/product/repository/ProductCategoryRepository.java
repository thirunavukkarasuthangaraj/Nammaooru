package com.shopmanagement.product.repository;

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
public interface ProductCategoryRepository extends JpaRepository<ProductCategory, Long>, JpaSpecificationExecutor<ProductCategory> {

    // Find by basic properties
    Optional<ProductCategory> findBySlug(String slug);
    List<ProductCategory> findByIsActiveTrue();
    List<ProductCategory> findByIsActiveTrueOrderBySortOrder();

    // Parent-child relationship queries
    List<ProductCategory> findByParentIsNullAndIsActiveTrue(); // Root categories
    List<ProductCategory> findByParentIdAndIsActiveTrue(Long parentId);
    
    @Query("SELECT c FROM ProductCategory c WHERE c.parent = :parent AND c.isActive = true ORDER BY c.sortOrder")
    List<ProductCategory> findSubcategoriesByParent(@Param("parent") ProductCategory parent);

    // Search and filtering
    @Query("SELECT c FROM ProductCategory c WHERE " +
           "LOWER(c.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(c.description) LIKE LOWER(CONCAT('%', :search, '%'))")
    Page<ProductCategory> searchCategories(@Param("search") String search, Pageable pageable);

    // Category hierarchy queries
    @Query("SELECT c FROM ProductCategory c WHERE c.parent IS NULL ORDER BY c.sortOrder")
    List<ProductCategory> findRootCategories();

    @Query("SELECT COUNT(c) FROM ProductCategory c WHERE c.parent.id = :parentId AND c.isActive = true")
    long countSubcategoriesByParent(@Param("parentId") Long parentId);

    // Check for existing categories
    boolean existsByNameAndParentId(String name, Long parentId);
    boolean existsBySlug(String slug);

    // Category with product count
    @Query("SELECT c, COUNT(p) FROM ProductCategory c " +
           "LEFT JOIN c.products p " +
           "WHERE c.isActive = true " +
           "GROUP BY c " +
           "ORDER BY c.sortOrder")
    List<Object[]> findCategoriesWithProductCount();

    // Additional methods for ProductCategoryService
    @Query("SELECT c FROM ProductCategory c WHERE c.parent IS NULL AND (:activeOnly IS NULL OR c.isActive = :activeOnly) ORDER BY c.sortOrder")
    List<ProductCategory> findRootCategoriesOrderedBySort(@Param("activeOnly") Boolean activeOnly);

    @Query("SELECT c FROM ProductCategory c WHERE c.parent.id = :parentId AND c.isActive = true ORDER BY c.sortOrder")
    List<ProductCategory> findActiveSubcategoriesOrderedBySort(@Param("parentId") Long parentId);

    @Query("SELECT c FROM ProductCategory c WHERE c.parent.id = :parentId ORDER BY c.sortOrder")
    List<ProductCategory> findSubcategoriesOrderedBySort(@Param("parentId") Long parentId);

    @Query("SELECT COALESCE(MAX(c.sortOrder), 0) FROM ProductCategory c WHERE " +
           "(:parentId IS NULL AND c.parent IS NULL) OR c.parent.id = :parentId")
    Integer getMaxSortOrderForParent(@Param("parentId") Long parentId);

    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM ProductCategory c WHERE c.parent.id = :parentId")
    boolean hasSubcategories(@Param("parentId") Long parentId);

    @Query(value = "WITH RECURSIVE category_tree AS (" +
           "SELECT id, parent_id, name, description, slug, is_active, sort_order, icon_url, created_by, updated_by, created_at, updated_at " +
           "FROM product_categories WHERE id = :categoryId " +
           "UNION ALL " +
           "SELECT c.id, c.parent_id, c.name, c.description, c.slug, c.is_active, c.sort_order, c.icon_url, c.created_by, c.updated_by, c.created_at, c.updated_at " +
           "FROM product_categories c " +
           "JOIN category_tree ct ON c.parent_id = ct.id) " +
           "SELECT * FROM category_tree WHERE id != :categoryId", nativeQuery = true)
    List<ProductCategory> findAllDescendants(@Param("categoryId") Long categoryId);
}