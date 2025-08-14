package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ProductCategoryRequest;
import com.shopmanagement.product.dto.ProductCategoryResponse;
import com.shopmanagement.product.service.ProductCategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products/categories")
@RequiredArgsConstructor
@Slf4j
public class ProductCategoryController {

    private final ProductCategoryService categoryService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProductCategoryResponse>>> getAllCategories(
            @RequestParam(required = false) Long parentId,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDirection) {
        
        log.info("Fetching categories - page: {}, size: {}, parentId: {}", page, size, parentId);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<ProductCategoryResponse> categories = categoryService.getCategories(
                parentId, isActive, search, pageable);
        
        return ResponseEntity.ok(ApiResponse.success(categories, "Categories fetched successfully"));
    }

    @GetMapping("/tree")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryTree(
            @RequestParam(required = false) Long rootId,
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching category tree - rootId: {}, activeOnly: {}", rootId, activeOnly);
        List<ProductCategoryResponse> tree = categoryService.getCategoryTree(rootId, activeOnly);
        return ResponseEntity.ok(ApiResponse.success(tree, "Category tree fetched successfully"));
    }

    @GetMapping("/root")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getRootCategories(
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching root categories - activeOnly: {}", activeOnly);
        List<ProductCategoryResponse> categories = categoryService.getRootCategories(activeOnly);
        return ResponseEntity.ok(ApiResponse.success(categories, "Root categories fetched successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getCategoryById(@PathVariable Long id) {
        log.info("Fetching category by ID: {}", id);
        ProductCategoryResponse category = categoryService.getCategoryById(id);
        return ResponseEntity.ok(ApiResponse.success(category, "Category fetched successfully"));
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getCategoryBySlug(@PathVariable String slug) {
        log.info("Fetching category by slug: {}", slug);
        ProductCategoryResponse category = categoryService.getCategoryBySlug(slug);
        return ResponseEntity.ok(ApiResponse.success(category, "Category fetched successfully"));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> createCategory(
            @Valid @RequestBody ProductCategoryRequest request) {
        log.info("Creating category: {}", request.getName());
        ProductCategoryResponse category = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(category, "Category created successfully"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody ProductCategoryRequest request) {
        log.info("Updating category: {}", id);
        ProductCategoryResponse category = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(ApiResponse.success(category, "Category updated successfully"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Long id) {
        log.info("Deleting category: {}", id);
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Category deleted successfully"));
    }

    @GetMapping("/{id}/subcategories")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getSubcategories(
            @PathVariable Long id,
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching subcategories for category: {}", id);
        List<ProductCategoryResponse> subcategories = categoryService.getSubcategories(id, activeOnly);
        return ResponseEntity.ok(ApiResponse.success(subcategories, "Subcategories fetched successfully"));
    }

    @GetMapping("/{id}/path")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryPath(@PathVariable Long id) {
        log.info("Fetching category path for: {}", id);
        List<ProductCategoryResponse> path = categoryService.getCategoryPath(id);
        return ResponseEntity.ok(ApiResponse.success(path, "Category path fetched successfully"));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> updateCategoryStatus(
            @PathVariable Long id,
            @RequestParam Boolean isActive) {
        log.info("Updating category status: {} - active: {}", id, isActive);
        ProductCategoryResponse category = categoryService.updateCategoryStatus(id, isActive);
        return ResponseEntity.ok(ApiResponse.success(category, "Category status updated successfully"));
    }

    @PatchMapping("/reorder")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> reorderCategories(
            @RequestBody List<Long> categoryIds) {
        log.info("Reordering categories: {}", categoryIds.size());
        List<ProductCategoryResponse> categories = categoryService.reorderCategories(categoryIds);
        return ResponseEntity.ok(ApiResponse.success(categories, "Categories reordered successfully"));
    }
}