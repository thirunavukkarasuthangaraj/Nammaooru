package com.shopmanagement.customer.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ShopProductResponse;
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

@RestController("customerShopControllerUnique")
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerShopController {

    private final ShopService shopService;
    private final ShopProductService shopProductService;

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
        
        log.info("Customer fetching products for shop: {} - page: {}, size: {}", shopId, page, size);
        
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
    public ResponseEntity<ApiResponse<List<String>>> getShopCategories(@PathVariable Long shopId) {
        log.info("Customer fetching categories for shop: {}", shopId);
        
        List<String> categories = shopProductService.getShopProductCategories(shopId);
        return ResponseEntity.ok(ApiResponse.success(categories, "Categories fetched successfully"));
    }
}