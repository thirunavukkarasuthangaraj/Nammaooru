package com.shopmanagement.controller;

import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.service.ShopDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shops/dashboard")
@RequiredArgsConstructor
@CrossOrigin(originPatterns = {"*"})
public class ShopDashboardController {

    private final ShopDashboardService dashboardService;

    @GetMapping("/todays-revenue")
    public ResponseEntity<ApiResponse<Double>> getTodaysRevenue(Authentication authentication) {
        try {
            Double revenue = dashboardService.getTodaysRevenue(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(revenue, "Today's revenue retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0.0, "No revenue data available"));
        }
    }

    @GetMapping("/todays-orders")
    public ResponseEntity<ApiResponse<Long>> getTodaysOrderCount(Authentication authentication) {
        try {
            Long count = dashboardService.getTodaysOrderCount(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(count, "Today's order count retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0L, "No order data available"));
        }
    }

    @GetMapping("/product-count")
    public ResponseEntity<ApiResponse<Long>> getProductCount(Authentication authentication) {
        try {
            Long count = dashboardService.getProductCount(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(count, "Product count retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0L, "No product data available"));
        }
    }

    @GetMapping("/low-stock-count")
    public ResponseEntity<ApiResponse<Long>> getLowStockCount(Authentication authentication) {
        try {
            Long count = dashboardService.getLowStockCount(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(count, "Low stock count retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0L, "No low stock data available"));
        }
    }

    @GetMapping("/recent-orders")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getRecentOrders(
            @RequestParam(defaultValue = "5") int limit, 
            Authentication authentication) {
        try {
            List<Map<String, Object>> orders = dashboardService.getRecentOrders(authentication.getName(), limit);
            return ResponseEntity.ok(ApiResponse.success(orders, "Recent orders retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(List.of(), "No recent orders available"));
        }
    }

    @GetMapping("/low-stock-products")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getLowStockProducts(
            @RequestParam(defaultValue = "10") int limit, 
            Authentication authentication) {
        try {
            List<Map<String, Object>> products = dashboardService.getLowStockProducts(authentication.getName(), limit);
            return ResponseEntity.ok(ApiResponse.success(products, "Low stock products retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(List.of(), "No low stock products available"));
        }
    }

    @GetMapping("/customer-count")
    public ResponseEntity<ApiResponse<Long>> getCustomerCount(Authentication authentication) {
        try {
            Long count = dashboardService.getCustomerCount(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(count, "Customer count retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0L, "No customer data available"));
        }
    }

    @GetMapping("/new-customers")
    public ResponseEntity<ApiResponse<Long>> getNewCustomerCount(Authentication authentication) {
        try {
            Long count = dashboardService.getNewCustomerCount(authentication.getName());
            return ResponseEntity.ok(ApiResponse.success(count, "New customer count retrieved successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(ApiResponse.success(0L, "No new customer data available"));
        }
    }
}