package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/shop-products")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
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
                        Page.empty(),
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
                    Page.empty(),
                    "Error fetching products: " + e.getMessage()
            ));
        }
    }
}