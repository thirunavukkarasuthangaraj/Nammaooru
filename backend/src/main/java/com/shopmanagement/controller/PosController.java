package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.PosOrderRequest;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.service.PosService;
import com.shopmanagement.common.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/pos")
@RequiredArgsConstructor
public class PosController {

    private final PosService posService;

    /**
     * Create a POS order for walk-in customer
     */
    @PostMapping("/orders")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> createPosOrder(
            @Valid @RequestBody PosOrderRequest request) {
        log.info("Creating POS order for shop: {}", request.getShopId());
        OrderResponse response = posService.createPosOrder(request);
        return ResponseUtil.created(response, "POS order created successfully");
    }

    /**
     * Sync multiple offline orders
     */
    @PostMapping("/orders/sync")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> syncOfflineOrders(
            @Valid @RequestBody List<PosOrderRequest> requests) {
        log.info("Syncing {} offline orders", requests.size());
        List<OrderResponse> responses = posService.syncOfflineOrders(requests);

        Map<String, Object> result = new HashMap<>();
        result.put("synced", responses.size());
        result.put("total", requests.size());
        result.put("orders", responses);

        return ResponseUtil.success(result, "Offline orders synced successfully");
    }

    /**
     * Get all products for a shop (for offline caching)
     * Returns lightweight product data optimized for POS
     */
    @GetMapping("/products/{shopId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getProductsForCache(
            @PathVariable Long shopId) {
        log.info("Fetching products for POS cache - shop: {}", shopId);

        List<ShopProduct> products = posService.getShopProductsForCache(shopId);

        // Return lightweight data for caching
        List<Map<String, Object>> productData = products.stream()
                .map(this::mapToLightweightProduct)
                .collect(Collectors.toList());

        return ResponseUtil.success(productData, "Products fetched for cache");
    }

    /**
     * Map ShopProduct to lightweight format for offline cache
     * Optimized for minimal data transfer and fast search
     */
    private Map<String, Object> mapToLightweightProduct(ShopProduct product) {
        Map<String, Object> data = new HashMap<>();
        data.put("id", product.getId());
        data.put("name", product.getCustomName() != null
                ? product.getCustomName()
                : product.getMasterProduct().getName());
        data.put("nameTamil", product.getMasterProduct().getNameTamil());
        data.put("price", product.getPrice());
        data.put("stock", product.getStockQuantity());
        data.put("trackInventory", product.getTrackInventory());
        data.put("sku", product.getMasterProduct().getSku());
        data.put("barcode", product.getMasterProduct().getBarcode());
        data.put("image", product.getMasterProduct().getPrimaryImageUrl());
        data.put("categoryId", product.getMasterProduct().getCategory() != null
                ? product.getMasterProduct().getCategory().getId()
                : null);
        data.put("categoryName", product.getMasterProduct().getCategory() != null
                ? product.getMasterProduct().getCategory().getName()
                : null);
        data.put("unit", product.getMasterProduct().getBaseUnit());
        data.put("weight", product.getMasterProduct().getBaseWeight());
        return data;
    }
}
