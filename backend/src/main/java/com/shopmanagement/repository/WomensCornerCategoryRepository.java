package com.shopmanagement.repository;

import com.shopmanagement.entity.WomensCornerCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WomensCornerCategoryRepository extends JpaRepository<WomensCornerCategory, Long> {

    List<WomensCornerCategory> findByIsActiveTrueOrderByDisplayOrderAsc();
}
