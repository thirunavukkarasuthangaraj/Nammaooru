package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ProductCategoryRequest;
import com.shopmanagement.product.dto.ProductCategoryResponse;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProductCategoryService {

    private final ProductCategoryRepository categoryRepository;
    private final ProductMapper productMapper;

    @Transactional(readOnly = true)
    public Page<ProductCategoryResponse> getCategories(Long parentId, Boolean isActive, String search, Pageable pageable) {
        Specification<ProductCategory> spec = Specification.where(null);
        
        if (parentId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("parent").get("id"), parentId));
        } else {
            // If no parent specified, get root categories
            spec = spec.and((root, query, cb) -> cb.isNull(root.get("parent")));
        }
        
        if (isActive != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("isActive"), isActive));
        }
        
        if (StringUtils.hasText(search)) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("name")), searchPattern),
                cb.like(cb.lower(root.get("description")), searchPattern),
                cb.like(cb.lower(root.get("slug")), searchPattern)
            ));
        }
        
        Page<ProductCategory> categoryPage = categoryRepository.findAll(spec, pageable);
        return categoryPage.map(productMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<ProductCategoryResponse> getCategoryTree(Long rootId, Boolean activeOnly) {
        List<ProductCategory> rootCategories;
        
        if (rootId != null) {
            ProductCategory rootCategory = categoryRepository.findById(rootId)
                    .orElseThrow(() -> new RuntimeException("Category not found with id: " + rootId));
            rootCategories = List.of(rootCategory);
        } else {
            rootCategories = activeOnly ? 
                categoryRepository.findRootCategoriesOrderedBySort(true) :
                categoryRepository.findRootCategoriesOrderedBySort(null);
        }
        
        return rootCategories.stream()
                .map(category -> buildCategoryTree(category, activeOnly))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductCategoryResponse> getRootCategories(Boolean activeOnly) {
        List<ProductCategory> categories = activeOnly ? 
            categoryRepository.findRootCategoriesOrderedBySort(true) :
            categoryRepository.findRootCategoriesOrderedBySort(null);
        return productMapper.toCategoryResponses(categories);
    }

    @Transactional(readOnly = true)
    public ProductCategoryResponse getCategoryById(Long id) {
        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        return productMapper.toResponse(category);
    }

    @Transactional(readOnly = true)
    public ProductCategoryResponse getCategoryBySlug(String slug) {
        ProductCategory category = categoryRepository.findBySlug(slug)
                .orElseThrow(() -> new RuntimeException("Category not found with slug: " + slug));
        return productMapper.toResponse(category);
    }

    public ProductCategoryResponse createCategory(ProductCategoryRequest request) {
        log.info("Creating category: {}", request.getName());
        
        // Validate slug uniqueness
        String slug = StringUtils.hasText(request.getSlug()) ? 
            request.getSlug() : generateSlug(request.getName());
            
        if (categoryRepository.existsBySlug(slug)) {
            throw new RuntimeException("Category with slug already exists: " + slug);
        }
        
        // Get parent category if specified
        ProductCategory parent = null;
        if (request.getParentId() != null) {
            parent = categoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new RuntimeException("Parent category not found with id: " + request.getParentId()));
        }
        
        // Set sort order if not provided
        Integer sortOrder = request.getSortOrder();
        if (sortOrder == null) {
            sortOrder = categoryRepository.getMaxSortOrderForParent(request.getParentId()) + 1;
        }
        
        ProductCategory category = ProductCategory.builder()
                .name(request.getName())
                .description(request.getDescription())
                .slug(slug)
                .parent(parent)
                .isActive(request.getIsActive())
                .sortOrder(sortOrder)
                .iconUrl(request.getIconUrl())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        ProductCategory savedCategory = categoryRepository.save(category);
        log.info("Category created successfully with ID: {}", savedCategory.getId());
        
        return productMapper.toResponse(savedCategory);
    }

    public ProductCategoryResponse updateCategory(Long id, ProductCategoryRequest request) {
        log.info("Updating category: {}", id);
        
        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        
        // Validate slug uniqueness (excluding current category)
        String slug = StringUtils.hasText(request.getSlug()) ? 
            request.getSlug() : generateSlug(request.getName());
            
        if (!slug.equals(category.getSlug()) && categoryRepository.existsBySlug(slug)) {
            throw new RuntimeException("Category with slug already exists: " + slug);
        }
        
        // Validate parent change (prevent circular references)
        if (request.getParentId() != null && 
            (category.getParent() == null || !request.getParentId().equals(category.getParent().getId()))) {
            validateParentChange(id, request.getParentId());
            ProductCategory newParent = categoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new RuntimeException("Parent category not found"));
            category.setParent(newParent);
        } else if (request.getParentId() == null) {
            category.setParent(null);
        }
        
        // Update fields
        category.setName(request.getName());
        category.setDescription(request.getDescription());
        category.setSlug(slug);
        category.setIsActive(request.getIsActive());
        category.setSortOrder(request.getSortOrder());
        category.setIconUrl(request.getIconUrl());
        category.setUpdatedBy(getCurrentUsername());
        
        ProductCategory updatedCategory = categoryRepository.save(category);
        log.info("Category updated successfully: {}", id);
        
        return productMapper.toResponse(updatedCategory);
    }

    public void deleteCategory(Long id) {
        log.info("Deleting category: {}", id);
        
        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        
        // Check if category has subcategories
        if (categoryRepository.hasSubcategories(id)) {
            throw new RuntimeException("Cannot delete category with subcategories. Please delete subcategories first.");
        }
        
        // Check if category has products
        if (!category.getProducts().isEmpty()) {
            throw new RuntimeException("Cannot delete category with products. Please move products to another category first.");
        }
        
        categoryRepository.delete(category);
        log.info("Category deleted successfully: {}", id);
    }

    @Transactional(readOnly = true)
    public List<ProductCategoryResponse> getSubcategories(Long parentId, Boolean activeOnly) {
        List<ProductCategory> subcategories = activeOnly ?
            categoryRepository.findActiveSubcategoriesOrderedBySort(parentId) :
            categoryRepository.findSubcategoriesOrderedBySort(parentId);
        return productMapper.toCategoryResponses(subcategories);
    }

    @Transactional(readOnly = true)
    public List<ProductCategoryResponse> getCategoryPath(Long categoryId) {
        ProductCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + categoryId));
        
        List<ProductCategory> path = new ArrayList<>();
        ProductCategory current = category;
        
        while (current != null) {
            path.add(0, current); // Add to beginning to maintain order
            current = current.getParent();
        }
        
        return productMapper.toCategoryResponses(path);
    }

    public ProductCategoryResponse updateCategoryStatus(Long id, Boolean isActive) {
        log.info("Updating category status: {} - active: {}", id, isActive);
        
        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        
        category.setIsActive(isActive);
        category.setUpdatedBy(getCurrentUsername());
        
        // If deactivating, also deactivate all subcategories
        if (!isActive) {
            deactivateSubcategories(category);
        }
        
        ProductCategory updatedCategory = categoryRepository.save(category);
        log.info("Category status updated: {}", id);
        
        return productMapper.toResponse(updatedCategory);
    }

    public List<ProductCategoryResponse> reorderCategories(List<Long> categoryIds) {
        log.info("Reordering {} categories", categoryIds.size());
        
        List<ProductCategory> categories = categoryRepository.findAllById(categoryIds);
        
        IntStream.range(0, categoryIds.size())
                .forEach(i -> {
                    Long categoryId = categoryIds.get(i);
                    categories.stream()
                            .filter(cat -> cat.getId().equals(categoryId))
                            .findFirst()
                            .ifPresent(cat -> {
                                cat.setSortOrder(i + 1);
                                cat.setUpdatedBy(getCurrentUsername());
                            });
                });
        
        List<ProductCategory> savedCategories = categoryRepository.saveAll(categories);
        log.info("Categories reordered successfully");
        
        return savedCategories.stream()
                .sorted(Comparator.comparing(ProductCategory::getSortOrder))
                .map(productMapper::toResponse)
                .toList();
    }

    private ProductCategoryResponse buildCategoryTree(ProductCategory category, Boolean activeOnly) {
        ProductCategoryResponse response = productMapper.toResponse(category);
        
        List<ProductCategory> subcategories = activeOnly ?
            categoryRepository.findActiveSubcategoriesOrderedBySort(category.getId()) :
            categoryRepository.findSubcategoriesOrderedBySort(category.getId());
        
        List<ProductCategoryResponse> subcategoryResponses = subcategories.stream()
                .map(subcat -> buildCategoryTree(subcat, activeOnly))
                .toList();
        
        response.setSubcategories(subcategoryResponses);
        return response;
    }

    private void validateParentChange(Long categoryId, Long newParentId) {
        // Check if new parent is a descendant of current category (would create circular reference)
        List<ProductCategory> descendants = categoryRepository.findAllDescendants(categoryId);
        if (descendants.stream().anyMatch(desc -> desc.getId().equals(newParentId))) {
            throw new RuntimeException("Cannot set parent to a descendant category - this would create a circular reference");
        }
    }

    private void deactivateSubcategories(ProductCategory category) {
        category.getSubcategories().forEach(subcat -> {
            subcat.setIsActive(false);
            subcat.setUpdatedBy(getCurrentUsername());
            deactivateSubcategories(subcat); // Recursive deactivation
        });
    }

    private String generateSlug(String name) {
        return name.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "") // Remove special characters
                .replaceAll("\\s+", "-") // Replace spaces with hyphens
                .replaceAll("-+", "-") // Replace multiple hyphens with single
                .replaceAll("^-|-$", ""); // Remove leading/trailing hyphens
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
}