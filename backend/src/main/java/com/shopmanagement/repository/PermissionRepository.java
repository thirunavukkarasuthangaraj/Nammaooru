package com.shopmanagement.repository;

import com.shopmanagement.entity.Permission;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {
    
    // Basic finders
    Optional<Permission> findByName(String name);
    boolean existsByName(String name);
    
    // Find by status
    List<Permission> findByActiveTrue();
    Page<Permission> findByActiveTrue(Pageable pageable);
    
    // Find by category
    List<Permission> findByCategory(String category);
    Page<Permission> findByCategory(String category, Pageable pageable);
    
    // Find by resource type
    List<Permission> findByResourceType(String resourceType);
    Page<Permission> findByResourceType(String resourceType, Pageable pageable);
    
    // Find by action type
    List<Permission> findByActionType(String actionType);
    Page<Permission> findByActionType(String actionType, Pageable pageable);
    
    // Find by resource and action type
    List<Permission> findByResourceTypeAndActionType(String resourceType, String actionType);
    
    // Find permissions by IDs
    List<Permission> findByIdIn(Set<Long> ids);
    
    // Search permissions
    @Query("SELECT p FROM Permission p WHERE " +
           "LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.category) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.resourceType) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.actionType) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<Permission> searchPermissions(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    // Get all categories
    @Query("SELECT DISTINCT p.category FROM Permission p WHERE p.category IS NOT NULL ORDER BY p.category")
    List<String> findAllCategories();
    
    // Get all resource types
    @Query("SELECT DISTINCT p.resourceType FROM Permission p WHERE p.resourceType IS NOT NULL ORDER BY p.resourceType")
    List<String> findAllResourceTypes();
    
    // Get all action types
    @Query("SELECT DISTINCT p.actionType FROM Permission p WHERE p.actionType IS NOT NULL ORDER BY p.actionType")
    List<String> findAllActionTypes();
    
    // Analytics queries
    @Query("SELECT COUNT(p) FROM Permission p WHERE p.category = :category")
    Long countPermissionsByCategory(@Param("category") String category);
    
    @Query("SELECT p.category, COUNT(p) FROM Permission p WHERE p.category IS NOT NULL GROUP BY p.category")
    List<Object[]> getPermissionCountByCategory();
    
    @Query("SELECT p.resourceType, COUNT(p) FROM Permission p WHERE p.resourceType IS NOT NULL GROUP BY p.resourceType")
    List<Object[]> getPermissionCountByResourceType();
}