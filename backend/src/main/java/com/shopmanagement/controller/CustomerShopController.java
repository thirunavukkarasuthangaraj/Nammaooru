package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.product.service.ShopProductService;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class CustomerShopController {

    private final ShopService shopService;
    private final ShopProductService shopProductService;

    @GetMapping("/shops")
    public ResponseEntity<ApiResponse<List<ShopResponse>>> getShopsForCustomers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        
        try {
            log.info("Customer shops request - search: {}, category: {}", search, category);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ShopResponse> shops;
            
            if (search != null && !search.trim().isEmpty()) {
                shops = shopService.searchShops(search, pageable);
            } else {
                shops = shopService.getAllShops(pageable);
            }
            
            // Filter only approved and active shops for customers
            List<ShopResponse> customerShops = shops.getContent().stream()
                    .filter(shop -> "APPROVED".equals(shop.getStatus()) && Boolean.TRUE.equals(shop.getIsActive()))
                    .toList();
            
            return ResponseUtil.success(customerShops, "Shops retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving shops for customers", e);
            return ResponseUtil.error("Failed to retrieve shops");
        }
    }

    @GetMapping("/shops/{shopId}")
    public ResponseEntity<ApiResponse<ShopResponse>> getShopById(@PathVariable Long shopId) {
        try {
            log.info("Customer shop details request for shop ID: {}", shopId);
            
            ShopResponse shop = shopService.getShopById(shopId);
            
            // Only return approved and active shops
            if (!"APPROVED".equals(shop.getStatus()) || !Boolean.TRUE.equals(shop.getIsActive())) {
                return ResponseUtil.error("Shop not available");
            }
            
            return ResponseUtil.success(shop, "Shop details retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving shop details for customer", e);
            return ResponseUtil.error("Shop not found");
        }
    }

    @GetMapping("/shops/{shopId}/products")
    public ResponseEntity<ApiResponse<List<ShopProductResponse>>> getShopProducts(
            @PathVariable Long shopId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        
        try {
            log.info("Customer products request for shop ID: {}, search: {}, category: {}", 
                    shopId, search, category);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ShopProductResponse> products;
            
            if (search != null && !search.trim().isEmpty()) {
                products = shopProductService.searchShopProducts(shopId, search, pageable);
            } else {
                // Use the getShopProducts method with null specification for all products
                products = shopProductService.getShopProducts(shopId, null, pageable);
            }
            
            // Filter only available and in-stock products for customers
            List<ShopProductResponse> customerProducts = products.getContent().stream()
                    .filter(product -> Boolean.TRUE.equals(product.getIsAvailable()) && 
                            (product.getInStock() == null || Boolean.TRUE.equals(product.getInStock())))
                    .toList();
            
            return ResponseUtil.success(customerProducts, "Products retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving products for customer", e);
            return ResponseUtil.error("Failed to retrieve products");
        }
    }

    @GetMapping("/shops/{shopId}/categories")
    public ResponseEntity<ApiResponse<List<String>>> getShopCategories(@PathVariable Long shopId) {
        try {
            log.info("Customer categories request for shop ID: {}", shopId);
            
            // For now, return empty list as category functionality is not implemented in ShopProductService
            List<String> categories = List.of();
            
            return ResponseUtil.success(categories, "Categories retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving categories for customer", e);
            return ResponseUtil.error("Failed to retrieve categories");
        }
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<ShopResponse>>> searchShopsAndProducts(
            @RequestParam String query,
            @RequestParam(defaultValue = "shops") String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            log.info("Customer search request - query: {}, type: {}", query, type);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ShopResponse> results = shopService.searchShops(query, pageable);
            
            // Filter only approved and active shops
            List<ShopResponse> customerResults = results.getContent().stream()
                    .filter(shop -> "APPROVED".equals(shop.getStatus()) && Boolean.TRUE.equals(shop.getIsActive()))
                    .toList();
            
            return ResponseUtil.success(customerResults, "Search results retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error performing customer search", e);
            return ResponseUtil.error("Search failed");
        }
    }
}