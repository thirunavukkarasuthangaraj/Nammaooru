package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shop-products")
@RequiredArgsConstructor
@Slf4j
public class ShopOwnerProductController {

    private final ShopProductService shopProductService;
    private final ShopService shopService;

    @GetMapping("/my-products")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Page<ShopProductResponse>>> getMyProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {

        log.info("Fetching my products for current user - search: {}, page: {}, size: {}", search, page, size);

        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);

            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.ok(ApiResponse.success(
                        Page.empty(PageRequest.of(page, size)),
                        "No shop found for current user"
                ));
            }

            Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));

            // Build specification with filters
            Specification<ShopProduct> spec = (root, query, cb) ->
                cb.notEqual(root.get("status"), ShopProduct.ShopProductStatus.INACTIVE);

            // Add search filter - handle null fields with coalesce (includes all barcodes for scanning)
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.toLowerCase().trim() + "%";
                spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(cb.coalesce(root.get("customName"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("customDescription"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("masterProduct").get("name"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("masterProduct").get("nameTamil"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("masterProduct").get("sku"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("masterProduct").get("barcode"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("barcode1"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("barcode2"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("barcode3"), "")), searchPattern),
                    cb.like(cb.lower(cb.coalesce(root.get("tags"), "")), searchPattern)
                ));
            }

            // Add category filter
            if (categoryId != null) {
                spec = spec.and((root, query, cb) ->
                    cb.equal(root.get("masterProduct").get("category").get("id"), categoryId));
            }

            // Add status filter
            if (status != null && !status.trim().isEmpty()) {
                if ("available".equalsIgnoreCase(status)) {
                    spec = spec.and((root, query, cb) -> cb.equal(root.get("isAvailable"), true));
                } else if ("unavailable".equalsIgnoreCase(status)) {
                    spec = spec.and((root, query, cb) -> cb.equal(root.get("isAvailable"), false));
                } else {
                    try {
                        ShopProduct.ShopProductStatus statusEnum = ShopProduct.ShopProductStatus.valueOf(status.toUpperCase());
                        spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), statusEnum));
                    } catch (IllegalArgumentException e) {
                        log.warn("Invalid status filter: {}", status);
                    }
                }
            }

            Page<ShopProductResponse> products = shopProductService.getShopProducts(currentShop.getId(), spec, pageable);

            log.info("Found {} products for shop: {} (owner: {}) with search: {}",
                products.getTotalElements(), currentShop.getId(), currentUsername, search);

            return ResponseEntity.ok(ApiResponse.success(
                    products,
                    "My products fetched successfully"
            ));

        } catch (Exception e) {
            log.error("Error fetching my products for user: {}", currentUsername, e);
            return ResponseEntity.ok(ApiResponse.success(
                    Page.empty(PageRequest.of(page, size)),
                    "Error fetching products: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/create")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> createProduct(
            @Valid @RequestBody ShopProductRequest request) {
        
        log.info("Creating product for current user");
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }
            
            ShopProductResponse product = shopProductService.addProductToShop(currentShop.getId(), request);
            
            log.info("Product created successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                    product,
                    "Product created successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error creating product for user: {}", currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error creating product: " + e.getMessage()
            ));
        }
    }

    @PutMapping("/{productId}")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateProduct(
            @PathVariable Long productId,
            @RequestBody ShopProductRequest request) {  // Removed @Valid - no validation needed for UPDATE

        log.info("Updating product {} for current user (masterProductId not required for updates)", productId);

        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);

            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }

            log.debug("Calling updateShopProduct with: shopId={}, productId={}, request={}", currentShop.getId(), productId, request);
            ShopProductResponse product = shopProductService.updateShopProduct(currentShop.getId(), productId, request);

            log.info("Product updated successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);

            return ResponseEntity.ok(ApiResponse.success(
                    product,
                    "Product updated successfully"
            ));

        } catch (Exception e) {
            log.error("Error updating product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error updating product: " + e.getMessage()
            ));
        }
    }

    @DeleteMapping("/{productId}")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long productId) {

        log.info("Deleting product {} for current user", productId);

        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);

            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }

            shopProductService.removeProductFromShop(currentShop.getId(), productId);

            log.info("Product deleted successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);

            return ResponseEntity.ok(ApiResponse.success(
                    (Void) null,
                    "Product deleted successfully"
            ));

        } catch (Exception e) {
            log.error("Error deleting product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error deleting product: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/bulk-delete")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> bulkDeleteProducts(
            @RequestBody Map<String, Object> request) {

        // Handle Integer to Long conversion (Jackson deserializes numbers as Integer)
        @SuppressWarnings("unchecked")
        List<Number> rawIds = (List<Number>) request.get("productIds");
        List<Long> productIds = rawIds != null
                ? rawIds.stream().map(Number::longValue).toList()
                : null;

        if (productIds == null || productIds.isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "No product IDs provided for deletion"
            ));
        }

        log.info("Bulk deleting {} products for current user", productIds.size());

        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);

            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }

            int successCount = 0;
            int errorCount = 0;

            for (Long productId : productIds) {
                try {
                    shopProductService.removeProductFromShop(currentShop.getId(), productId);
                    successCount++;
                } catch (Exception e) {
                    log.error("Error deleting product {} during bulk delete: {}", productId, e.getMessage());
                    errorCount++;
                }
            }

            log.info("Bulk delete completed for shop: {} (owner: {}) - success: {}, errors: {}",
                    currentShop.getId(), currentUsername, successCount, errorCount);

            Map<String, Object> result = Map.of(
                    "totalRequested", productIds.size(),
                    "successCount", successCount,
                    "errorCount", errorCount
            );

            return ResponseEntity.ok(ApiResponse.success(
                    result,
                    String.format("%d products deleted successfully", successCount)
            ));

        } catch (Exception e) {
            log.error("Error in bulk delete for user: {}", currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error deleting products: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/{productId}")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> getProduct(@PathVariable Long productId) {
        
        log.info("Fetching product {} for current user", productId);
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }
            
            ShopProductResponse product = shopProductService.getShopProduct(currentShop.getId(), productId);
            
            log.info("Product fetched successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);
            
            return ResponseEntity.ok(ApiResponse.success(
                    product,
                    "Product fetched successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error fetching product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error fetching product: " + e.getMessage()
            ));
        }
    }

    @PatchMapping("/{productId}/inventory")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateInventory(
            @PathVariable Long productId,
            @RequestParam Integer quantity,
            @RequestParam String operation) {
        
        log.info("Updating inventory for product {} - operation: {} - quantity: {}", productId, operation, quantity);
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }
            
            ShopProductResponse product = shopProductService.updateInventory(currentShop.getId(), productId, quantity, operation);
            
            log.info("Inventory updated successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);
            
            return ResponseEntity.ok(ApiResponse.success(
                    product,
                    "Inventory updated successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error updating inventory for product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error updating inventory: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProductStats() {
        
        log.info("Fetching product statistics for current user");
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }
            
            Map<String, Object> stats = shopProductService.getShopProductStats(currentShop.getId());
            
            log.info("Product statistics fetched successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);
            
            return ResponseEntity.ok(ApiResponse.success(
                    stats,
                    "Product statistics fetched successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error fetching product statistics for user: {}", currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error fetching product statistics: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/available-master-products")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Page<com.shopmanagement.product.dto.MasterProductResponse>>> getAvailableMasterProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String brand,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching available master products for current user - page: {}, size: {}", page, size);
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.ok(ApiResponse.success(
                        Page.empty(PageRequest.of(page, size)),
                        "No shop found for current user"
                ));
            }
            
            Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
            
            // Get available master products (excluding ones already in this shop)
            Page<com.shopmanagement.product.dto.MasterProductResponse> products = 
                shopProductService.getAvailableMasterProducts(currentShop.getId(), search, categoryId, brand, pageable);
            
            log.info("Found {} available master products for shop: {} (owner: {})", 
                products.getTotalElements(), currentShop.getId(), currentUsername);
            
            return ResponseEntity.ok(ApiResponse.success(
                    products,
                    "Available master products fetched successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error fetching available master products for user: {}", currentUsername, e);
            return ResponseEntity.ok(ApiResponse.success(
                    Page.empty(PageRequest.of(page, size)),
                    "Error fetching available products: " + e.getMessage()
            ));
        }
    }

    /**
     * Quick update endpoint for POS - update price, MRP, and stock only
     */
    @PatchMapping("/{productId}/quick-update")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> quickUpdateProduct(
            @PathVariable Long productId,
            @RequestBody Map<String, Object> updates) {

        log.info("Quick update for product {} - updates: {}", productId, updates);

        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);

            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user"
                ));
            }

            // Build partial update request
            ShopProductRequest request = new ShopProductRequest();

            if (updates.containsKey("price")) {
                Object priceObj = updates.get("price");
                if (priceObj instanceof Number) {
                    request.setPrice(java.math.BigDecimal.valueOf(((Number) priceObj).doubleValue()));
                }
            }

            if (updates.containsKey("originalPrice")) {
                Object mrpObj = updates.get("originalPrice");
                if (mrpObj instanceof Number) {
                    request.setOriginalPrice(java.math.BigDecimal.valueOf(((Number) mrpObj).doubleValue()));
                }
            }

            if (updates.containsKey("stockQuantity")) {
                Object stockObj = updates.get("stockQuantity");
                if (stockObj instanceof Number) {
                    request.setStockQuantity(((Number) stockObj).intValue());
                }
            }

            if (updates.containsKey("barcode")) {
                Object barcodeObj = updates.get("barcode");
                if (barcodeObj != null) {
                    request.setBarcode(barcodeObj.toString());
                }
            }

            // Shop-level multiple barcodes
            if (updates.containsKey("barcode1")) {
                Object barcodeObj = updates.get("barcode1");
                request.setBarcode1(barcodeObj != null ? barcodeObj.toString() : null);
            }
            if (updates.containsKey("barcode2")) {
                Object barcodeObj = updates.get("barcode2");
                request.setBarcode2(barcodeObj != null ? barcodeObj.toString() : null);
            }
            if (updates.containsKey("barcode3")) {
                Object barcodeObj = updates.get("barcode3");
                request.setBarcode3(barcodeObj != null ? barcodeObj.toString() : null);
            }

            ShopProductResponse product = shopProductService.quickUpdateProduct(currentShop.getId(), productId, request);

            log.info("Product quick updated successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);

            return ResponseEntity.ok(ApiResponse.success(
                    product,
                    "Product updated successfully"
            ));

        } catch (Exception e) {
            log.error("Error quick updating product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error updating product: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/low-stock")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getLowStockProducts() {
        
        log.info("Fetching low stock products for current user");
        
        // Get current user's shop
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        
        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            
            if (currentShop == null) {
                log.warn("No shop found for user: {}", currentUsername);
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }
            
            List<ShopProductResponse> products = shopProductService.getLowStockProducts(currentShop.getId());
            
            log.info("Low stock products fetched successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);
            
            return ResponseEntity.ok(ApiResponse.success(
                    products,
                    "Low stock products fetched successfully"
            ));
            
        } catch (Exception e) {
            log.error("Error fetching low stock products for user: {}", currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error fetching low stock products: " + e.getMessage()
            ));
        }
    }
}