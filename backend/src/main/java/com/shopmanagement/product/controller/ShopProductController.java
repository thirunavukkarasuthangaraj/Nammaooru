package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.service.GeminiSearchService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/shops/{shopId}/products")
@RequiredArgsConstructor
@Slf4j
public class ShopProductController {

    private final ShopProductService shopProductService;
    private final GeminiSearchService geminiSearchService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ShopProductResponse>>> getShopProducts(
            @PathVariable Long shopId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) ShopProduct.ShopProductStatus status,
            @RequestParam(required = false) Boolean isFeatured,
            @RequestParam(required = false) Boolean isAvailable,
            @RequestParam(required = false) Boolean inStock,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching products for shop: {} - page: {}, size: {}", shopId, page, size);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Specification<ShopProduct> spec = Specification.where(null);
        
        if (categoryId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("masterProduct").get("category").get("id"), categoryId));
        }
        
        if (brand != null && !brand.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("masterProduct").get("brand"), brand));
        }
        
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        
        if (isFeatured != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("isFeatured"), isFeatured));
        }
        
        if (isAvailable != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("isAvailable"), isAvailable));
        }
        
        if (inStock != null && inStock) {
            spec = spec.and((root, query, cb) -> cb.greaterThan(root.get("stockQuantity"), 0));
        }
        
        if (minPrice != null) {
            spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("price"), minPrice));
        }
        
        if (maxPrice != null) {
            spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("price"), maxPrice));
        }
        
        if (search != null && !search.isEmpty()) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("masterProduct").get("name")), searchPattern),
                cb.like(cb.lower(root.get("masterProduct").get("sku")), searchPattern),
                cb.like(cb.lower(root.get("customName")), searchPattern),
                cb.like(cb.lower(root.get("customDescription")), searchPattern),
                cb.like(cb.lower(root.get("tags")), searchPattern)
            ));
        }
        
        Page<ShopProductResponse> products = shopProductService.getShopProducts(shopId, spec, pageable);
        
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Shop products fetched successfully"
        ));
    }

    // AI Search endpoint - MUST come before /{productId} to avoid path variable conflict
    @GetMapping("/ai-search")
    public ResponseEntity<ApiResponse<Map<String, Object>>> aiSearchProducts(
            @PathVariable Long shopId,
            @RequestParam String query) {
        log.info("🤖 AI Search - Shop: {}, Query: \"{}\"", shopId, query);

        try {
            // Get all products from the shop
            Pageable pageable = PageRequest.of(0, 1000); // Get a large number of products
            Specification<ShopProduct> spec = Specification.where(null);
            Page<ShopProductResponse> allProducts = shopProductService.getShopProducts(shopId, spec, pageable);

            // Build product name list for AI matching (include both English and Tamil names)
            List<String> productNames = allProducts.getContent().stream()
                    .map(p -> {
                        String name = p.getDisplayName(); // Use displayName which is computed field
                        String tamilName = p.getMasterProduct() != null ? p.getMasterProduct().getNameTamil() : null;
                        if (tamilName != null && !tamilName.isEmpty()) {
                            return name + " | " + tamilName;
                        }
                        return name;
                    })
                    .collect(Collectors.toList());

            // Use Gemini AI to find matching products
            List<String> aiMatches = geminiSearchService.enhanceSearchQuery(query, productNames);

            // Filter products based on AI matches
            List<ShopProductResponse> matchedProducts = new ArrayList<>();

            if (aiMatches.isEmpty()) {
                // If AI returns nothing, use regular text search as fallback (not all products)
                log.info("⚠️ AI returned no matches, falling back to text search for: {}", query);
                Pageable searchPageable = PageRequest.of(0, 100);
                Page<ShopProductResponse> searchResults = shopProductService.searchShopProducts(shopId, query, searchPageable);
                matchedProducts = searchResults.getContent();
                log.info("📝 Text search found {} products for query: {}", matchedProducts.size(), query);
            } else {
                // Match products by name (handle both English and Tamil)
                for (ShopProductResponse product : allProducts.getContent()) {
                    String productName = product.getDisplayName(); // Use displayName
                    String tamilName = product.getMasterProduct() != null ? product.getMasterProduct().getNameTamil() : null;

                    for (String aiMatch : aiMatches) {
                        // Remove Tamil part if present (format: "Name | தமிழ்")
                        String cleanMatch = aiMatch.split("\\|")[0].trim();

                        if (productName.equalsIgnoreCase(cleanMatch) ||
                            (tamilName != null && tamilName.equalsIgnoreCase(cleanMatch)) ||
                            aiMatch.toLowerCase().contains(productName.toLowerCase()) ||
                            (tamilName != null && aiMatch.contains(tamilName))) {
                            matchedProducts.add(product);
                            break;
                        }
                    }
                }
                log.info("✅ AI matched {} products out of {} total", matchedProducts.size(), allProducts.getContent().size());
            }

            // Build response
            Map<String, Object> response = new HashMap<>();
            response.put("query", query);
            response.put("matchedProducts", matchedProducts);
            response.put("totalProducts", allProducts.getContent().size());
            response.put("matchCount", matchedProducts.size());

            return ResponseEntity.ok(ApiResponse.success(
                    response,
                    "AI search completed successfully"
            ));

        } catch (Exception e) {
            log.error("❌ Error in AI search: {}", e.getMessage(), e);

            // Fallback: use regular text search instead of showing all products
            log.info("⚠️ AI error, falling back to text search for: {}", query);
            Pageable searchPageable = PageRequest.of(0, 100);
            Page<ShopProductResponse> searchResults = shopProductService.searchShopProducts(shopId, query, searchPageable);

            Map<String, Object> fallbackResponse = new HashMap<>();
            fallbackResponse.put("query", query);
            fallbackResponse.put("matchedProducts", searchResults.getContent());
            fallbackResponse.put("totalProducts", searchResults.getTotalElements());
            fallbackResponse.put("matchCount", searchResults.getContent().size());
            fallbackResponse.put("error", "AI search failed, using text search");

            return ResponseEntity.ok(ApiResponse.success(
                    fallbackResponse,
                    "AI search failed, using text search as fallback"
            ));
        }
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<ShopProductResponse>>> searchShopProducts(
            @PathVariable Long shopId,
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching products in shop: {} with query: {}", shopId, query);
        Pageable pageable = PageRequest.of(page, size);
        Page<ShopProductResponse> products = shopProductService.searchShopProducts(shopId, query, pageable);
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Search results fetched successfully"
        ));
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getFeaturedProducts(
            @PathVariable Long shopId) {
        log.info("Fetching featured products for shop: {}", shopId);
        List<ShopProductResponse> products = shopProductService.getFeaturedProducts(shopId);
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Featured products fetched successfully"
        ));
    }

    @GetMapping("/low-stock")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getLowStockProducts(
            @PathVariable Long shopId) {
        log.info("Fetching low stock products for shop: {}", shopId);
        List<ShopProductResponse> products = shopProductService.getLowStockProducts(shopId);
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Low stock products fetched successfully"
        ));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopProductStats(
            @PathVariable Long shopId) {
        log.info("Fetching product statistics for shop: {}", shopId);
        Map<String, Object> stats = shopProductService.getShopProductStats(shopId);
        return ResponseEntity.ok(ApiResponse.success(
                stats,
                "Shop product statistics fetched successfully"
        ));
    }

    @GetMapping("/{productId}")
    public ResponseEntity<ApiResponse<ShopProductResponse>> getShopProduct(
            @PathVariable Long shopId,
            @PathVariable Long productId) {
        log.info("Fetching shop product: {} for shop: {}", productId, shopId);
        ShopProductResponse product = shopProductService.getShopProduct(shopId, productId);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Shop product fetched successfully"
        ));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> addProductToShop(
            @PathVariable Long shopId,
            @Valid @RequestBody ShopProductRequest request) {
        log.info("Adding product to shop: {}", shopId);
        ShopProductResponse product = shopProductService.addProductToShop(shopId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                product,
                "Product added to shop successfully"
        ));
    }

    @PutMapping("/{productId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateShopProduct(
            @PathVariable Long shopId,
            @PathVariable Long productId,
            @Valid @RequestBody ShopProductRequest request) {
        log.info("Updating shop product: {} for shop: {}", productId, shopId);
        ShopProductResponse product = shopProductService.updateShopProduct(shopId, productId, request);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Shop product updated successfully"
        ));
    }

    @DeleteMapping("/{productId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Void>> removeProductFromShop(
            @PathVariable Long shopId,
            @PathVariable Long productId) {
        log.info("Removing product from shop: {} - product: {}", shopId, productId);
        shopProductService.removeProductFromShop(shopId, productId);
        return ResponseEntity.ok(ApiResponse.success(
                (Void) null,
                "Product removed from shop successfully"
        ));
    }

    @PatchMapping("/{productId}/inventory")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateInventory(
            @PathVariable Long shopId,
            @PathVariable Long productId,
            @RequestParam Integer quantity,
            @RequestParam String operation) {
        log.info("Updating inventory for shop: {} - product: {} - operation: {} - quantity: {}",
                shopId, productId, operation, quantity);
        ShopProductResponse product = shopProductService.updateInventory(shopId, productId, quantity, operation);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Inventory updated successfully"
        ));
    }
}