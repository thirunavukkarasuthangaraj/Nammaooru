package com.shopmanagement.repository;

import com.shopmanagement.entity.ComboItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComboItemRepository extends JpaRepository<ComboItem, Long> {

    // Find all items for a combo
    List<ComboItem> findByComboIdOrderByDisplayOrderAsc(Long comboId);

    // Delete all items for a combo
    void deleteByComboId(Long comboId);

    // Check if a product is in any active combo
    @Query("SELECT CASE WHEN COUNT(ci) > 0 THEN true ELSE false END FROM ComboItem ci " +
           "WHERE ci.shopProduct.id = :shopProductId AND ci.combo.isActive = true")
    boolean isProductInActiveCombo(@Param("shopProductId") Long shopProductId);

    // Find combos containing a specific product
    @Query("SELECT ci.combo.id FROM ComboItem ci WHERE ci.shopProduct.id = :shopProductId")
    List<Long> findComboIdsContainingProduct(@Param("shopProductId") Long shopProductId);

    // Count items in a combo
    Long countByComboId(Long comboId);
}
