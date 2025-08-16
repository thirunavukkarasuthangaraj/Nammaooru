package com.shopmanagement.repository;

import com.shopmanagement.entity.Setting;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SettingRepository extends JpaRepository<Setting, Long> {
    
    // Basic finders
    Optional<Setting> findBySettingKey(String settingKey);
    boolean existsBySettingKey(String settingKey);
    
    // Find by scope
    List<Setting> findByScope(Setting.SettingScope scope);
    Page<Setting> findByScope(Setting.SettingScope scope, Pageable pageable);
    
    // Find by category
    List<Setting> findByCategory(String category);
    Page<Setting> findByCategory(String category, Pageable pageable);
    
    // Find by setting type
    List<Setting> findBySettingType(Setting.SettingType settingType);
    Page<Setting> findBySettingType(Setting.SettingType settingType, Pageable pageable);
    
    // Find active settings
    List<Setting> findByIsActiveTrue();
    Page<Setting> findByIsActiveTrue(Pageable pageable);
    
    // Find required settings
    List<Setting> findByIsRequiredTrue();
    
    // Find by shop
    List<Setting> findByShopId(Long shopId);
    Page<Setting> findByShopId(Long shopId, Pageable pageable);
    
    // Find by user
    List<Setting> findByUserId(Long userId);
    Page<Setting> findByUserId(Long userId, Pageable pageable);
    
    // Find global settings
    @Query("SELECT s FROM Setting s WHERE s.scope = 'GLOBAL'")
    List<Setting> findGlobalSettings();
    
    @Query("SELECT s FROM Setting s WHERE s.scope = 'GLOBAL'")
    Page<Setting> findGlobalSettings(Pageable pageable);
    
    // Find shop-specific settings
    @Query("SELECT s FROM Setting s WHERE s.scope = 'SHOP' AND s.shopId = :shopId")
    List<Setting> findShopSettings(@Param("shopId") Long shopId);
    
    // Find user-specific settings
    @Query("SELECT s FROM Setting s WHERE s.scope = 'USER' AND s.userId = :userId")
    List<Setting> findUserSettings(@Param("userId") Long userId);
    
    // Find settings by scope and shop/user
    @Query("SELECT s FROM Setting s WHERE s.scope = :scope AND (s.shopId = :shopId OR s.scope != 'SHOP') AND (s.userId = :userId OR s.scope != 'USER')")
    List<Setting> findSettingsByContext(@Param("scope") Setting.SettingScope scope, 
                                       @Param("shopId") Long shopId, 
                                       @Param("userId") Long userId);
    
    // Search settings
    @Query("SELECT s FROM Setting s WHERE " +
           "LOWER(s.settingKey) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.category) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<Setting> searchSettings(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    // Find settings by category and scope
    @Query("SELECT s FROM Setting s WHERE s.category = :category AND s.scope = :scope")
    List<Setting> findByCategoryAndScope(@Param("category") String category, 
                                        @Param("scope") Setting.SettingScope scope);
    
    // Find distinct categories
    @Query("SELECT DISTINCT s.category FROM Setting s WHERE s.category IS NOT NULL ORDER BY s.category")
    List<String> findDistinctCategories();
    
    // Find categories by scope
    @Query("SELECT DISTINCT s.category FROM Setting s WHERE s.scope = :scope AND s.category IS NOT NULL ORDER BY s.category")
    List<String> findCategoriesByScope(@Param("scope") Setting.SettingScope scope);
    
    // Find settings ordered by display order
    @Query("SELECT s FROM Setting s WHERE s.category = :category ORDER BY s.displayOrder ASC, s.settingKey ASC")
    List<Setting> findByCategoryOrderByDisplayOrder(@Param("category") String category);
    
    // Count settings by scope
    @Query("SELECT COUNT(s) FROM Setting s WHERE s.scope = :scope")
    Long countByScope(@Param("scope") Setting.SettingScope scope);
    
    // Count settings by category
    @Query("SELECT COUNT(s) FROM Setting s WHERE s.category = :category")
    Long countByCategory(@Param("category") String category);
    
    // Find settings that need validation
    @Query("SELECT s FROM Setting s WHERE s.validationRules IS NOT NULL AND s.validationRules != ''")
    List<Setting> findSettingsWithValidation();
    
    // Find read-only settings
    List<Setting> findByIsReadOnlyTrue();
    
    // Find settings by key pattern
    @Query("SELECT s FROM Setting s WHERE s.settingKey LIKE :pattern")
    List<Setting> findBySettingKeyPattern(@Param("pattern") String pattern);
    
    // Bulk operations
    @Query("UPDATE Setting s SET s.isActive = :isActive WHERE s.category = :category")
    void updateActiveStatusByCategory(@Param("category") String category, @Param("isActive") Boolean isActive);
    
    @Query("DELETE FROM Setting s WHERE s.scope = :scope AND s.shopId = :shopId")
    void deleteByShopId(@Param("scope") Setting.SettingScope scope, @Param("shopId") Long shopId);
    
    @Query("DELETE FROM Setting s WHERE s.scope = :scope AND s.userId = :userId")
    void deleteByUserId(@Param("scope") Setting.SettingScope scope, @Param("userId") Long userId);
}