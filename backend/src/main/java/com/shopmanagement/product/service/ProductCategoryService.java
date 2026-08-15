package com.shopmanagement.product.service;

import com.shopmanagement.entity.User;
import com.shopmanagement.product.dto.ProductCategoryRequest;
import com.shopmanagement.product.dto.ProductCategoryResponse;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
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
    private final com.shopmanagement.product.repository.MasterProductRepository masterProductRepository;
    private final ProductMapper productMapper;
    private final com.shopmanagement.product.repository.ShopProductRepository shopProductRepository;
    private final com.shopmanagement.shop.repository.ShopRepository shopRepository;
    private final com.shopmanagement.repository.UserRepository userRepository;

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

        // Shop owners see platform/global categories and categories owned by their shop only.
        if (isShopOwner()) {
            Long currentShopId = findCurrentOwnerShopId().orElse(-1L);
            spec = spec.and((root, query, cb) -> {
                Subquery<Long> usedByCurrentShop = query.subquery(Long.class);
                Root<com.shopmanagement.product.entity.ShopProduct> product = usedByCurrentShop
                        .from(com.shopmanagement.product.entity.ShopProduct.class);
                usedByCurrentShop.select(product.get("masterProduct").get("category").get("id"))
                        .where(cb.equal(product.get("shop").get("id"), currentShopId));
                return cb.or(
                        cb.equal(root.get("ownerShopId"), currentShopId),
                        root.get("id").in(usedByCurrentShop),
                        cb.and(cb.isNull(root.get("ownerShopId")), cb.or(
                                cb.isNull(root.get("createdBy")),
                                cb.equal(root.get("createdBy"), "admin"),
                                cb.equal(root.get("createdBy"), "superadmin"))));
            });
        }
        
        Page<ProductCategory> categoryPage = categoryRepository.findAll(spec, pageable);
        Page<ProductCategoryResponse> responses = categoryPage.map(productMapper::toResponse);

        // Shop owners should see how many of THEIR products are in each category,
        // not the master-catalog product count
        if (isShopOwner()) {
            findCurrentOwnerShopId().ifPresent(shopId -> {
                java.util.Map<Long, Long> countsByCategory = new java.util.HashMap<>();
                for (Object[] row : shopProductRepository.countProductsPerCategoryByShopId(shopId)) {
                    countsByCategory.put((Long) row[0], (Long) row[1]);
                }
                responses.forEach(r ->
                        r.setProductCount(countsByCategory.getOrDefault(r.getId(), 0L)));
            });
        }

        return responses;
    }

    /** Shop owner's products whose master product has no category (0 for other roles) */
    @Transactional(readOnly = true)
    public long getUncategorizedProductCount() {
        if (!isShopOwner()) {
            return 0;
        }
        return findCurrentOwnerShopId()
                .map(shopProductRepository::countUncategorizedByShopId)
                .orElse(0L);
    }

    private java.util.Optional<Long> findCurrentOwnerShopId() {
        String username = getCurrentUsername();
        return shopRepository.findByCreatedBy(username)
                .or(() -> userRepository.findByUsername(username)
                        .flatMap(user -> shopRepository.findByOwnerEmail(user.getEmail())))
                .map(com.shopmanagement.shop.entity.Shop::getId);
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
        
        // Slug is globally unique (DB constraint) but categories are per-shop,
        // so another shop's "dish-wash" must not block this owner's "Dish Wash".
        // Auto-suffix to a free slug instead of rejecting the save.
        String slug = StringUtils.hasText(request.getSlug()) ?
            request.getSlug() : generateSlug(request.getName());
        slug = nextFreeSlug(slug, null);
        
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
                .ownerShopId(isShopOwner() ? findCurrentOwnerShopId().orElse(null) : null)
                .build();
        
        ProductCategory savedCategory = categoryRepository.save(category);
        log.info("Category created successfully with ID: {}", savedCategory.getId());
        
        return productMapper.toResponse(savedCategory);
    }

    public ProductCategoryResponse updateCategory(Long id, ProductCategoryRequest request) {
        log.info("Updating category: {}", id);
        
        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        assertCanModify(category);

        // Validate slug uniqueness (excluding current category)
        String slug = StringUtils.hasText(request.getSlug()) ? 
            request.getSlug() : generateSlug(request.getName());
            
        if (!slug.equals(category.getSlug())) {
            slug = nextFreeSlug(slug, category.getSlug());
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

        // The category rename/move doesn't change any ShopProduct row itself, so the
        // POS/My-Products delta sync (which filters on ShopProduct.updatedAt) would
        // never notice - shop owners would see the old category name in the browser
        // for up to 24h (until the next full re-sync). Touch affected products so the
        // very next delta sync (within 5 minutes) picks up the rename.
        int touched = shopProductRepository.touchProductsByCategoryId(id);
        log.info("Category updated successfully: {} ({} product(s) marked for re-sync)", id, touched);

        return productMapper.toResponse(updatedCategory);
    }

    public void deleteCategory(Long id) {
        log.info("Deleting category: {}", id);

        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        assertCanModify(category);

        // Check if category has subcategories
        if (categoryRepository.hasSubcategories(id)) {
            throw new RuntimeException("Cannot delete category with subcategories. Please delete subcategories first.");
        }

        // Touch products BEFORE detaching - once detached they no longer match
        // this categoryId and the delta sync would never learn they lost it.
        shopProductRepository.touchProductsByCategoryId(id);

        // Detach products instead of blocking the delete - they remain in the
        // shop's product listing as "uncategorized"
        int detached = masterProductRepository.detachProductsFromCategory(id);

        categoryRepository.delete(category);
        log.info("Category {} deleted successfully ({} products left uncategorized)", id, detached);
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
        assertCanModify(category);

        category.setIsActive(isActive);
        category.setUpdatedBy(getCurrentUsername());

        // If deactivating, also deactivate all subcategories
        if (!isActive) {
            deactivateSubcategories(category);
        }

        ProductCategory updatedCategory = categoryRepository.save(category);
        shopProductRepository.touchProductsByCategoryId(id);
        log.info("Category status updated: {}", id);

        return productMapper.toResponse(updatedCategory);
    }

    public ProductCategoryResponse updateCategoryImage(Long id, String imageUrl) {
        log.info("Updating category image: {} - imageUrl: {}", id, imageUrl);

        ProductCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        assertCanModify(category);

        category.setIconUrl(imageUrl);
        category.setUpdatedBy(getCurrentUsername());

        ProductCategory updatedCategory = categoryRepository.save(category);
        log.info("Category image updated: {}", id);

        return productMapper.toResponse(updatedCategory);
    }

    public List<ProductCategoryResponse> reorderCategories(List<Long> categoryIds) {
        log.info("Reordering {} categories", categoryIds.size());
        
        List<ProductCategory> categories = categoryRepository.findAllById(categoryIds);
        categories.forEach(this::assertCanModify);

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

    /** First free slug: base, base-2, base-3… (currentSlug stays valid for updates) */
    private String nextFreeSlug(String base, String currentSlug) {
        String candidate = base;
        int n = 2;
        while (!candidate.equals(currentSlug) && categoryRepository.existsBySlug(candidate)) {
            candidate = base + "-" + n++;
        }
        return candidate;
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

    private boolean isShopOwner() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SHOP_OWNER"));
    }

    private void assertCanModify(ProductCategory category) {
        if (isShopOwner() && !getCurrentUsername().equals(category.getCreatedBy())) {
            throw new RuntimeException("You can only modify categories created by you");
        }
    }
}
