package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.WomensCornerCategory;
import com.shopmanagement.repository.WomensCornerCategoryRepository;
import com.shopmanagement.service.FileUploadService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/womens-corner/categories")
@RequiredArgsConstructor
@Slf4j
public class WomensCornerCategoryController {

    private final WomensCornerCategoryRepository categoryRepository;
    private final FileUploadService fileUploadService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<WomensCornerCategory>>> getActiveCategories() {
        try {
            List<WomensCornerCategory> categories = categoryRepository.findByIsActiveTrueOrderByDisplayOrderAsc();
            return ResponseUtil.success(categories, "Categories retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching women's corner categories", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<WomensCornerCategory>>> getAllCategories() {
        try {
            List<WomensCornerCategory> categories = categoryRepository.findAll();
            return ResponseUtil.success(categories, "All categories retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching all women's corner categories", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerCategory>> createCategory(
            @RequestParam("name") String name,
            @RequestParam(value = "tamilName", required = false) String tamilName,
            @RequestParam(value = "color", required = false) String color,
            @RequestParam(value = "displayOrder", required = false, defaultValue = "0") Integer displayOrder,
            @RequestParam(value = "image", required = false) MultipartFile image) {
        try {
            String imageUrl = null;
            if (image != null && !image.isEmpty()) {
                imageUrl = fileUploadService.uploadFile(image, "womens-corner-categories");
            }

            WomensCornerCategory category = WomensCornerCategory.builder()
                    .name(name)
                    .tamilName(tamilName)
                    .imageUrl(imageUrl)
                    .color(color)
                    .displayOrder(displayOrder)
                    .build();

            WomensCornerCategory saved = categoryRepository.save(category);
            log.info("Women's corner category created: id={}, name={}", saved.getId(), name);
            return ResponseUtil.created(saved, "Category created successfully");
        } catch (Exception e) {
            log.error("Error creating women's corner category", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping(value = "/{id}", consumes = "multipart/form-data")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerCategory>> updateCategory(
            @PathVariable Long id,
            @RequestParam("name") String name,
            @RequestParam(value = "tamilName", required = false) String tamilName,
            @RequestParam(value = "color", required = false) String color,
            @RequestParam(value = "displayOrder", required = false) Integer displayOrder,
            @RequestParam(value = "isActive", required = false) Boolean isActive,
            @RequestParam(value = "image", required = false) MultipartFile image) {
        try {
            WomensCornerCategory category = categoryRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Category not found"));

            category.setName(name);
            if (tamilName != null) category.setTamilName(tamilName);
            if (color != null) category.setColor(color);
            if (displayOrder != null) category.setDisplayOrder(displayOrder);
            if (isActive != null) category.setIsActive(isActive);

            if (image != null && !image.isEmpty()) {
                // Delete old image
                if (category.getImageUrl() != null) {
                    fileUploadService.deleteFile(category.getImageUrl());
                }
                category.setImageUrl(fileUploadService.uploadFile(image, "womens-corner-categories"));
            }

            WomensCornerCategory saved = categoryRepository.save(category);
            log.info("Women's corner category updated: id={}", id);
            return ResponseUtil.success(saved, "Category updated successfully");
        } catch (Exception e) {
            log.error("Error updating women's corner category", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Long id) {
        try {
            WomensCornerCategory category = categoryRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Category not found"));

            if (category.getImageUrl() != null) {
                fileUploadService.deleteFile(category.getImageUrl());
            }

            categoryRepository.delete(category);
            log.info("Women's corner category deleted: id={}", id);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting women's corner category", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
