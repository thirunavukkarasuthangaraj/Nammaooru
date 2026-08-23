package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ProductImageResponse;
import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.service.ProductImageService;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shop-products")
@RequiredArgsConstructor
@Slf4j
public class ShopOwnerProductController {

    private final ShopProductService shopProductService;
    private final ShopService shopService;
    private final ProductImageService productImageService;

    private static final HttpClient IMAGE_HTTP_CLIENT = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10))
            // Bing's async results endpoint only responds with tiles when the
            // session carries cookies from a prior page load
            .cookieHandler(new java.net.CookieManager())
            .build();

    private static final long MAX_DOWNLOAD_IMAGE_BYTES = 8L * 1024 * 1024;

    @GetMapping("/my-products")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Page<ShopProductResponse>>> getMyProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection,
            @RequestParam(required = false) Long updatedAfter) {

        log.info("Fetching my products for current user - search: {}, page: {}, size: {}, updatedAfter: {}", search, page, size, updatedAfter);

        // Hard cap page size to protect server from oversized requests
        if (size > 500) {
            log.warn("Client requested size={} for /my-products; capping to 500", size);
            size = 500;
        }
        if (size <= 0) {
            size = 100;
        }

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

            // Build specification - show all products (including INACTIVE) so owner can manage them
            Specification<ShopProduct> spec = Specification.where(null);

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

            // Delta sync: only products changed after the given epoch-millis timestamp
            if (updatedAfter != null && updatedAfter > 0) {
                java.time.LocalDateTime since = java.time.LocalDateTime.ofInstant(
                        java.time.Instant.ofEpochMilli(updatedAfter), java.time.ZoneId.systemDefault());
                spec = spec.and((root, query, cb) -> cb.greaterThan(root.get("updatedAt"), since));
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

    @PatchMapping("/{productId}/availability")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ShopProductResponse>> updateProductAvailability(
            @PathVariable Long productId,
            @RequestBody Map<String, Object> request) {

        log.info("Updating availability for product {} - request: {}", productId, request);

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

            Boolean isAvailable = (Boolean) request.get("isAvailable");
            if (isAvailable == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("isAvailable field is required"));
            }

            ShopProductResponse product = shopProductService.updateProductAvailability(
                    currentShop.getId(), productId, isAvailable);

            log.info("Product availability updated successfully for shop: {} (owner: {})", currentShop.getId(), currentUsername);

            return ResponseEntity.ok(ApiResponse.success(
                    product,
                    isAvailable ? "Product activated successfully" : "Product deactivated successfully"
            ));

        } catch (Exception e) {
            log.error("Error updating availability for product {} for user: {}", productId, currentUsername, e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error updating product availability: " + e.getMessage()
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

            if (updates.containsKey("sku")) {
                Object skuObj = updates.get("sku");
                request.setSku(skuObj != null ? skuObj.toString() : null);
            }

            if (updates.containsKey("customName")) {
                Object nameObj = updates.get("customName");
                request.setCustomName(nameObj != null ? nameObj.toString() : null);
            }

            if (updates.containsKey("nameTamil")) {
                Object nameTamilObj = updates.get("nameTamil");
                request.setNameTamil(nameTamilObj != null ? nameTamilObj.toString() : null);
            }

            if (updates.containsKey("categoryName")) {
                Object categoryObj = updates.get("categoryName");
                request.setCategoryName(categoryObj != null ? categoryObj.toString() : null);
            }

            if (updates.containsKey("voiceSearchTags")) {
                Object tagsObj = updates.get("voiceSearchTags");
                request.setVoiceSearchTags(tagsObj != null ? tagsObj.toString() : null);
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

    /**
     * Upload image for a shop product
     */
    @PostMapping(value = "/{productId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadProductImage(
            @PathVariable Long productId,
            @RequestParam("file") MultipartFile file) {

        log.info("Uploading image for product: {}", productId);

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

            // Upload the image using ProductImageService
            MultipartFile[] files = new MultipartFile[]{file};
            List<ProductImageResponse> images = productImageService.uploadShopProductImages(
                    currentShop.getId(), productId, files, null);

            if (images.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Failed to upload image"));
            }

            String imageUrl = images.get(0).getImageUrl();
            log.info("Image uploaded successfully for product {}: {}", productId, imageUrl);

            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("imageUrl", imageUrl),
                    "Image uploaded successfully"
            ));

        } catch (Exception e) {
            log.error("Error uploading image for product {}: {}", productId, e.getMessage(), e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error uploading image: " + e.getMessage()
            ));
        }
    }

    /**
     * Search product images through DuckDuckGo Images (no API key required).
     * Returns [{label, thumb, url}] for the bulk-edit image picker.
     */
    @GetMapping("/image-search")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<Map<String, String>>>> searchProductImages(@RequestParam("q") String query) {
        try {
            String trimmedQuery = query == null ? "" : query.trim();
            if (trimmedQuery.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Product name is required"));
            }
            String searchQuery = trimmedQuery
                    + " grocery supermarket food product packet India"
                    + " -music -album -song -vinyl -record";
            String encodedQuery = URLEncoder.encode(searchQuery, StandardCharsets.UTF_8);
            String browserUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36";

            String searchPageUrl = "https://duckduckgo.com/?q=" + encodedQuery
                    + "&iax=images&ia=images";
            HttpRequest tokenRequest = HttpRequest.newBuilder(URI.create(searchPageUrl))
                    .timeout(Duration.ofSeconds(10))
                    .header("User-Agent", browserUa)
                    .header("Accept", "text/html")
                    .header("Accept-Language", "en-IN,en;q=0.9")
                    .GET()
                    .build();
            HttpResponse<String> tokenResponse = IMAGE_HTTP_CLIENT.send(
                    tokenRequest, HttpResponse.BodyHandlers.ofString());
            java.util.regex.Matcher tokenMatcher = java.util.regex.Pattern
                    .compile("vqd=\\\"([0-9-]+)\\\"")
                    .matcher(tokenResponse.body());
            if (tokenResponse.statusCode() != 200 || !tokenMatcher.find()) {
                log.error("DuckDuckGo image search token request failed with status {}",
                        tokenResponse.statusCode());
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "Image search failed, try again later"));
            }

            String url = "https://duckduckgo.com/i.js?l=in-en&o=json&q=" + encodedQuery
                    + "&vqd=" + tokenMatcher.group(1) + "&f=,,,&p=1";
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .header("User-Agent", browserUa)
                    .header("Accept", "application/json")
                    .header("Accept-Language", "en-IN,en;q=0.9")
                    .header("Referer", searchPageUrl)
                    .GET()
                    .build();
            HttpResponse<String> response = IMAGE_HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                log.error("DuckDuckGo image search failed with status {}", response.statusCode());
                return ResponseEntity.badRequest().body(ApiResponse.error("Image search failed, try again later"));
            }

            ObjectMapper mapper = new ObjectMapper();
            List<Map<String, String>> relevant = new ArrayList<>();
            Map<String, Integer> relevanceScores = new java.util.HashMap<>();
            java.util.Set<String> seenUrls = new java.util.HashSet<>();
            List<String> queryTokens = imageSearchTokens(trimmedQuery);
            JsonNode searchResults = mapper.readTree(response.body()).path("results");
            for (JsonNode node : searchResults) {
                if (relevant.size() >= 40) {
                    break;
                }
                try {
                    String imageUrl = node.path("image").asText("");
                    if (imageUrl.isEmpty() || !seenUrls.add(imageUrl)) {
                        continue;
                    }
                    String label = node.path("title").asText("");
                    Map<String, String> entry = Map.of(
                            "label", label,
                            "thumb", node.path("thumbnail").asText(imageUrl),
                            "url", imageUrl
                    );
                    int relevance = imageSearchRelevance(queryTokens, label, imageUrl);
                    if (relevance < 0) {
                        continue;
                    }
                    // Relevance is primary; common product-image formats are
                    // only a small tie-breaker.
                    String lower = imageUrl.toLowerCase();
                    if (lower.matches(".*\\.(jpe?g|png)([?#].*)?$")) {
                        relevance += 1;
                    }
                    relevant.add(entry);
                    relevanceScores.put(imageUrl, relevance);
                } catch (Exception ignore) {
                    // not a result tile — skip
                }
            }
            relevant.sort((left, right) -> Integer.compare(
                    relevanceScores.getOrDefault(right.get("url"), 0),
                    relevanceScores.getOrDefault(left.get("url"), 0)));
            List<Map<String, String>> results = new ArrayList<>(
                    relevant.subList(0, Math.min(20, relevant.size())));

            if (results.isEmpty()) {
                log.warn("DuckDuckGo image search returned no relevant results for '{}'", query);
            }
            return ResponseEntity.ok(ApiResponse.success(results, "Images found"));
        } catch (Exception e) {
            log.error("Error searching images for '{}': {}", query, e.getMessage(), e);
            return ResponseEntity.badRequest().body(ApiResponse.error("Image search failed: " + e.getMessage()));
        }
    }

    private static List<String> imageSearchTokens(String query) {
        java.util.Set<String> stopWords = java.util.Set.of(
                "and", "the", "with", "for", "from", "new", "pack", "product");
        List<String> tokens = new ArrayList<>();
        for (String token : normalizeImageSearchText(query).split(" ")) {
            if (token.length() >= 2
                    && !stopWords.contains(token)
                    && !token.matches("\\d+(ml|l|g|kg|gm|pcs|pc)")) {
                tokens.add(token);
            }
        }
        return tokens;
    }

    private static int imageSearchRelevance(
            List<String> queryTokens, String label, String imageUrl) {
        if (queryTokens.isEmpty()) {
            return -1;
        }

        String candidate = normalizeImageSearchText(label + " " + imageUrl);
        int matched = 0;
        int score = 0;
        for (String token : queryTokens) {
            if (candidate.contains(token)) {
                matched++;
                score += token.length() >= 5 ? 3 : 1;
            }
        }

        int minimumMatches = queryTokens.size() >= 3 ? 2 : 1;
        if (matched < minimumMatches) {
            return -1;
        }

        // Give a strong boost when the first two meaningful name terms occur
        // together, which normally represents the brand (e.g. "head shoulders").
        if (queryTokens.size() >= 2
                && candidate.contains(queryTokens.get(0) + " " + queryTokens.get(1))) {
            score += 6;
        }
        return score;
    }

    private static String normalizeImageSearchText(String value) {
        return (value == null ? "" : value)
                .toLowerCase(java.util.Locale.ROOT)
                .replace("&", " and ")
                .replaceAll("[^a-z0-9]+", " ")
                .trim();
    }

    /**
     * Download an image from a URL (picked in the image search dialog)
     * and store it as the product image via the normal upload pipeline.
     */
    @PostMapping("/{productId}/image-from-url")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadProductImageFromUrl(
            @PathVariable Long productId,
            @RequestBody Map<String, String> body) {

        String sourceUrl = body != null ? body.get("url") : null;
        if (sourceUrl == null || !(sourceUrl.startsWith("http://") || sourceUrl.startsWith("https://"))) {
            return ResponseEntity.badRequest().body(ApiResponse.error("A valid image URL is required"));
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();

        try {
            Shop currentShop = shopService.getShopByOwner(currentUsername);
            if (currentShop == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error("No shop found for current user"));
            }

            URI uri = URI.create(sourceUrl);
            // Block SSRF against internal hosts
            InetAddress address = InetAddress.getByName(uri.getHost());
            if (address.isLoopbackAddress() || address.isSiteLocalAddress()
                    || address.isLinkLocalAddress() || address.isAnyLocalAddress()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("URL not allowed"));
            }

            HttpRequest request = HttpRequest.newBuilder(uri)
                    .timeout(Duration.ofSeconds(15))
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
                    .header("Accept", "image/*,*/*;q=0.8")
                    .GET()
                    .build();
            HttpResponse<byte[]> response = IMAGE_HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofByteArray());

            if (response.statusCode() != 200 || response.body() == null || response.body().length == 0) {
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "Could not download image (HTTP " + response.statusCode() + ")"));
            }
            byte[] bytes = response.body();
            if (bytes.length > MAX_DOWNLOAD_IMAGE_BYTES) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Image is too large (max 8MB)"));
            }

            String contentType = response.headers().firstValue("Content-Type").orElse("image/jpeg");
            int semicolon = contentType.indexOf(';');
            if (semicolon > 0) {
                contentType = contentType.substring(0, semicolon).trim();
            }
            if (!contentType.startsWith("image/")) {
                return ResponseEntity.badRequest().body(ApiResponse.error("URL is not an image"));
            }
            String extension = switch (contentType) {
                case "image/png" -> "png";
                case "image/webp" -> "webp";
                case "image/gif" -> "gif";
                default -> "jpg";
            };

            MultipartFile file = new DownloadedImageFile(bytes, "product-" + productId + "." + extension, contentType);
            List<ProductImageResponse> images = productImageService.uploadShopProductImages(
                    currentShop.getId(), productId, new MultipartFile[]{file}, null);

            if (images.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Failed to save image"));
            }

            String imageUrl = images.get(0).getImageUrl();
            log.info("Image downloaded from URL and saved for product {}: {}", productId, imageUrl);
            return ResponseEntity.ok(ApiResponse.success(Map.of("imageUrl", imageUrl), "Image saved successfully"));

        } catch (Exception e) {
            log.error("Error downloading image from URL for product {}: {}", productId, e.getMessage(), e);
            return ResponseEntity.badRequest().body(ApiResponse.error("Error downloading image: " + e.getMessage()));
        }
    }

    /**
     * In-memory MultipartFile wrapper for images downloaded from a URL,
     * so they flow through the same upload pipeline as browser uploads.
     */
    private static class DownloadedImageFile implements MultipartFile {
        private final byte[] content;
        private final String filename;
        private final String contentType;

        DownloadedImageFile(byte[] content, String filename, String contentType) {
            this.content = content;
            this.filename = filename;
            this.contentType = contentType;
        }

        @Override
        public String getName() {
            return "file";
        }

        @Override
        public String getOriginalFilename() {
            return filename;
        }

        @Override
        public String getContentType() {
            return contentType;
        }

        @Override
        public boolean isEmpty() {
            return content.length == 0;
        }

        @Override
        public long getSize() {
            return content.length;
        }

        @Override
        public byte[] getBytes() {
            return content;
        }

        @Override
        public InputStream getInputStream() {
            return new ByteArrayInputStream(content);
        }

        @Override
        public void transferTo(File dest) throws IOException {
            Files.write(dest.toPath(), content);
        }
    }

    /**
     * Delete/remove image from a shop product
     */
    @DeleteMapping("/{productId}/image")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteProductImage(@PathVariable Long productId) {

        log.info("Deleting image for product: {}", productId);

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

            // Get the product images and delete them
            List<ProductImageResponse> images = productImageService.getShopProductImages(
                    currentShop.getId(), productId);

            for (ProductImageResponse image : images) {
                productImageService.deleteProductImage(image.getId());
            }

            log.info("All images deleted for product {}", productId);

            return ResponseEntity.ok(ApiResponse.success(
                    null,
                    "Image removed successfully"
            ));

        } catch (Exception e) {
            log.error("Error deleting image for product {}: {}", productId, e.getMessage(), e);
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "Error removing image: " + e.getMessage()
            ));
        }
    }
}