package com.shopmanagement.customer.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.customer.CategoryResponse;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController("customerShopControllerUnique")
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerShopController {

    private final ShopService shopService;
    private final ShopProductService shopProductService;
    private final ProductCategoryRepository categoryRepository;

    @GetMapping("/shops")
    public ResponseEntity<ApiResponse<Page<ShopResponse>>> getAllShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category) {
        
        log.info("Customer fetching shops - page: {}, size: {}, search: {}", page, size, search);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by("name"));
        Page<ShopResponse> shops = shopService.getActiveShops(pageable, search, category);
        
        return ResponseEntity.ok(ApiResponse.success(shops, "Shops fetched successfully"));
    }

    @GetMapping("/shops/{shopId}")
    public ResponseEntity<ApiResponse<ShopResponse>> getShopById(@PathVariable Long shopId) {
        log.info("Customer fetching shop details for ID: {}", shopId);
        
        ShopResponse shop = shopService.getShopById(shopId);
        return ResponseEntity.ok(ApiResponse.success(shop, "Shop details fetched successfully"));
    }

    @GetMapping("/shops/{shopId}/products")
    public ResponseEntity<ApiResponse<Page<ShopProductResponse>>> getShopProducts(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category) {
        
        log.info("Customer fetching products for shop: {} - page: {}, size: {}, category: {}, search: {}", shopId, page, size, category, search);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by("isFeatured").descending().and(Sort.by("customName")));
        
        // Only fetch available products for customers
        Page<ShopProductResponse> products = shopProductService.getAvailableShopProducts(shopId, search, category, pageable);
        
        return ResponseEntity.ok(ApiResponse.success(products, "Products fetched successfully"));
    }

    @GetMapping("/shops/{shopId}/products/{productId}")
    public ResponseEntity<ApiResponse<ShopProductResponse>> getProductDetails(
            @PathVariable Long shopId,
            @PathVariable Long productId) {
        
        log.info("Customer fetching product details - shopId: {}, productId: {}", shopId, productId);
        
        ShopProductResponse product = shopProductService.getProductDetails(shopId, productId);
        return ResponseEntity.ok(ApiResponse.success(product, "Product details fetched successfully"));
    }

    @GetMapping("/shops/{shopId}/categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getShopCategories(@PathVariable Long shopId) {
        log.info("Customer fetching categories for shop: {}", shopId);

        List<String> categoryNames = shopProductService.getShopProductCategories(shopId);
        List<CategoryResponse> categories = categoryNames.stream()
                .map(categoryName -> createCategoryResponse(categoryName, shopId))
                .toList();

        return ResponseEntity.ok(ApiResponse.success(categories, "Categories fetched successfully"));
    }

    private CategoryResponse createCategoryResponse(String categoryName, Long shopId) {
        CategoryResponse category = new CategoryResponse();
        category.setId(String.valueOf(categoryName.hashCode())); // Simple ID generation
        category.setName(categoryName);

        // Fetch actual category from database to get iconUrl
        Optional<ProductCategory> categoryEntity = categoryRepository.findByName(categoryName);

        // Add Tamil translations for common categories
        String displayName = getCategoryDisplayName(categoryName);
        category.setDisplayName(displayName);
        category.setDescription("Products in " + categoryName + " category");

        // Get actual product count for this category in this shop
        int productCount = shopProductService.getShopProductCountByCategory(shopId, categoryName);
        category.setProductCount(productCount);

        category.setIcon(getCategoryIcon(categoryName));
        category.setColor(getCategoryColor(categoryName));

        // Set imageUrl from database if available
        categoryEntity.ifPresent(cat -> {
            if (cat.getIconUrl() != null && !cat.getIconUrl().isEmpty()) {
                category.setImageUrl(cat.getIconUrl());
            }
        });

        return category;
    }

    private String getCategoryDisplayName(String categoryName) {
        switch (categoryName.toLowerCase()) {
            case "grocery":
                return "மளிகை / Grocery";
            case "vegetables":
                return "காய்கறிகள் / Vegetables";
            case "fruits":
                return "பழங்கள் / Fruits";
            case "dairy":
                return "பால் & முட்டை / Dairy";
            case "medicine":
                return "மருந்து / Medicine";
            case "rice":
                return "அரிசி & தானியங்கள் / Rice & Grains";
            default:
                return categoryName;
        }
    }

    private String getCategoryIcon(String categoryName) {
        switch (categoryName.toLowerCase()) {
            case "grocery":
                return "shopping_bag";
            case "vegetables":
                return "eco";
            case "fruits":
                return "apple";
            case "dairy":
                return "egg";
            case "medicine":
                return "medical_services";
            case "rice":
                return "rice_bowl";
            default:
                return "category";
        }
    }

    private String getCategoryColor(String categoryName) {
        switch (categoryName.toLowerCase()) {
            case "grocery":
                return "#4CAF50";
            case "vegetables":
                return "#4CAF50";
            case "fruits":
                return "#FF9800";
            case "dairy":
                return "#2196F3";
            case "medicine":
                return "#F44336";
            case "rice":
                return "#FFC107";
            default:
                return "#4CAF50";
        }
    }
}