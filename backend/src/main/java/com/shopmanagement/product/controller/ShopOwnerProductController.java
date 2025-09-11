package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
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
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching my products for current user - page: {}, size: {}", page, size);
        
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
            
            Page<ShopProductResponse> products = shopProductService.getShopProducts(currentShop.getId(), null, pageable);
            
            log.info("Found {} products for shop: {} (owner: {})", products.getTotalElements(), currentShop.getId(), currentUsername);
            
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
            @Valid @RequestBody ShopProductRequest request) {
        
        log.info("Updating product {} for current user", productId);
        
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