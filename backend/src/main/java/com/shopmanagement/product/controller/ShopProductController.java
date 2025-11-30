package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.service.ProductAISearchService;
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
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/shops/{shopId}/products")
@RequiredArgsConstructor
@Slf4j
public class ShopProductController {

    private final ShopProductService shopProductService;
    private final ProductAISearchService productAISearchService;
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
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {

        log.info("Fetching products for shop: {} - page: {}, size: {} (pagination: offset={}, limit={})",
                 shopId, page, size, (page * size), size);
        
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

    /**
     * Mobile app optimized pagination endpoint for customer app
     * Smart pagination: Categories load 20 items, General browsing loads 10 items
     *
     * USAGE EXAMPLES:
     * - All products (fast): GET /api/shops/1/products/mobile-list?page=0 → loads 10 items
     * - By category (more items): GET /api/shops/1/products/mobile-list?page=0&categoryId=5 → loads 20 items
     * - Next page: GET /api/shops/1/products/mobile-list?page=1&categoryId=5
     * - Search: GET /api/shops/1/products/mobile-list?page=0&search=rice
     *
     * SMART PAGE SIZING:
     * - categoryId present: Default size = 20 (category browsing - user wants more items)
     * - categoryId null: Default size = 10 (general browsing - faster loading)
     *
     * MOBILE APP IMPLEMENTATION:
     * 1. Load first page: page=0, categoryId=null (10 items, fast)
     * 2. User clicks category: Reset page=0, categoryId=5 (20 items, more options)
     * 3. User scrolls down: page=1, categoryId=5 (keeps same category, 20 items)
     * 4. Show "Load More" if hasNext=true
     */
    @GetMapping("/mobile-list")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProductsForMobileApp(
            @PathVariable Long shopId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String brand,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Integer size) {

        // Smart page sizing: 20 items for categories, 10 items for general browsing
        int pageSize = size != null ? size : (categoryId != null ? 20 : 10);

        log.info("⚡ Mobile app listing: shop={}, page={}, size={}, categoryId={}, mode={}",
                 shopId, page, pageSize, categoryId,
                 categoryId != null ? "CATEGORY_MODE (20 items)" : "GENERAL_MODE (10 items)");

        Sort.Direction direction = Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, pageSize, Sort.by(direction, "updatedAt"));

        Specification<ShopProduct> spec = (root, query, cb) -> cb.equal(root.get("shop").get("id"), shopId);

        if (search != null && !search.isEmpty()) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("masterProduct").get("name")), searchPattern),
                cb.like(cb.lower(root.get("customName")), searchPattern)
            ));
        }

        if (categoryId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("masterProduct").get("category").get("id"), categoryId));
        }

        if (brand != null && !brand.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("masterProduct").get("brand"), brand));
        }

        Page<ShopProductResponse> products = shopProductService.getShopProducts(shopId, spec, pageable);

        // Format response for mobile app "Load More" button
        Map<String, Object> mobileResponse = new HashMap<>();
        mobileResponse.put("products", products.getContent());
        mobileResponse.put("currentPage", page);
        mobileResponse.put("pageSize", pageSize); // Use calculated pageSize
        mobileResponse.put("totalProducts", products.getTotalElements());
        mobileResponse.put("totalPages", products.getTotalPages());
        mobileResponse.put("hasNext", products.hasNext());
        mobileResponse.put("hasPrevious", products.hasPrevious());
        mobileResponse.put("nextPage", page + 1);
        mobileResponse.put("categoryId", categoryId); // Return which category was filtered
        mobileResponse.put("mode", categoryId != null ? "CATEGORY_MODE (20 items)" : "GENERAL_MODE (10 items)"); // Show mode

        String filterInfo = categoryId != null ? String.format("category %d", categoryId) : "all categories";
        log.info("✅ Mobile response: {} products on page {}/{} from {}",
                 products.getContent().size(), page, products.getTotalPages(), filterInfo);

        return ResponseEntity.ok(ApiResponse.success(
                mobileResponse,
                String.format("Page %d of %d - %d products total", page + 1, products.getTotalPages(), products.getTotalElements())
        ));
    }

    // AI Search endpoint - MUST come before /{productId} to avoid path variable conflict
    @GetMapping("/ai-search")
    public ResponseEntity<ApiResponse<Map<String, Object>>> aiSearchProducts(
            @PathVariable Long shopId,
            @RequestParam String query) {
        // Preprocess query to convert natural language to comma-separated format
        String processedQuery = preprocessQuery(query);
        log.info("🤖 AI Search - Shop: {}, Original Query: \"{}\", Processed Query: \"{}\"", shopId, query, processedQuery);

        try {
            // First, use AI service with Tamil transliteration support
            Pageable pageable = PageRequest.of(0, 100);
            Page<MasterProductResponse> aiResults = productAISearchService.searchProductsByAI(processedQuery, pageable);

            log.info("✅ AI service found {} master products", aiResults.getTotalElements());

            // Now filter to only products available in this shop
            Specification<ShopProduct> spec = Specification.where(null);
            Page<ShopProductResponse> allShopProducts = shopProductService.getShopProducts(shopId, spec, PageRequest.of(0, 1000));

            List<ShopProductResponse> matchedProducts = new ArrayList<>();

            if (aiResults.getTotalElements() > 0) {
                // Match AI results with shop products
                Set<Long> masterProductIds = aiResults.getContent().stream()
                        .map(MasterProductResponse::getId)
                        .collect(Collectors.toSet());

                matchedProducts = allShopProducts.getContent().stream()
                        .filter(sp -> sp.getMasterProduct() != null && masterProductIds.contains(sp.getMasterProduct().getId()))
                        .limit(100)
                        .collect(Collectors.toList());

                log.info("📝 Found {} products in this shop from AI matches", matchedProducts.size());
            } else {
                // Fallback: If AI returns nothing and query looks like Tamil, try direct Tamil name matching
                if (isTamilText(query)) {
                    log.info("⚠️ AI returned 0 results for Tamil query, trying direct Tamil name matching");
                    matchedProducts = allShopProducts.getContent().stream()
                            .filter(p -> {
                                String tamilName = p.getMasterProduct() != null ? p.getMasterProduct().getNameTamil() : null;
                                return tamilName != null && tamilName.contains(query);
                            })
                            .collect(Collectors.toList());
                    log.info("✅ Tamil name matching found {} products", matchedProducts.size());
                }
            }

            // Build response
            Map<String, Object> response = new HashMap<>();
            response.put("query", query);  // Show original query to user
            response.put("processedQuery", processedQuery);  // Show processed query for transparency
            response.put("matchedProducts", matchedProducts);
            response.put("totalProducts", allShopProducts.getTotalElements());
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
            fallbackResponse.put("processedQuery", processedQuery);
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

    /**
     * Preprocess query to convert natural language to comma-separated format
     * Examples:
     *   "rice and dal" → "rice,dal"
     *   "milk & bread" → "milk,bread"
     *   "oil and salt and spice" → "oil,salt,spice"
     *   "rice" → "rice" (no change)
     *   "rice,dal" → "rice,dal" (already comma-separated)
     */
    private String preprocessQuery(String query) {
        if (query == null || query.trim().isEmpty()) {
            return query;
        }

        // If already contains commas, assume it's properly formatted
        if (query.contains(",")) {
            return query.trim();
        }

        // Convert natural language conjunctions to commas
        // Replace " and ", " & ", " or " with comma
        String processed = query
                .replaceAll("\\s+and\\s+", ",")  // "rice and dal" → "rice,dal"
                .replaceAll("\\s+&\\s+", ",")    // "rice & dal" → "rice,dal"
                .replaceAll("\\s+or\\s+", ",")   // "rice or dal" → "rice,dal"
                .trim();

        log.debug("Query preprocessing: \"{}\" → \"{}\"", query, processed);
        return processed;
    }

    /**
     * Check if text contains Tamil characters
     */
    private boolean isTamilText(String text) {
        return text != null && text.matches(".*[\\u0B80-\\u0BFF].*");
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