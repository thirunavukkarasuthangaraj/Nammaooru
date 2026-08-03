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
     * Send the bill for an already-created POS order to the customer via WhatsApp (as a PDF).
     */
    @PostMapping("/orders/{orderId}/send-whatsapp-bill")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Void>> sendBillViaWhatsApp(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> body) {
        String phone = body != null ? body.get("customerPhone") : null;
        String name = body != null ? body.get("customerName") : null;
        log.info("Sending WhatsApp bill for order: {}", orderId);
        posService.sendBillViaWhatsApp(orderId, phone, name);
        return ResponseUtil.success(null, "Bill sent via WhatsApp");
    }

    /**
     * Send the bill for an already-created POS order to the customer via email (as a PDF).
     */
    @PostMapping("/orders/{orderId}/send-email-bill")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Void>> sendBillViaEmail(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> body) {
        String email = body != null ? body.get("customerEmail") : null;
        String name = body != null ? body.get("customerName") : null;
        log.info("Sending email bill for order: {}", orderId);
        posService.sendBillViaEmail(orderId, email, name);
        return ResponseUtil.success(null, "Bill sent via email");
    }

    /**
     * Search customers previously billed at this shop (for POS customer autocomplete).
     * Matches by mobile number or name; returns name, phone, bill count and last visit.
     */
    @GetMapping("/customers/{shopId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> searchCustomers(
            @PathVariable Long shopId,
            @RequestParam(value = "q", required = false) String query,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        List<Map<String, Object>> customers = posService.searchCustomers(shopId, query, size);
        return ResponseUtil.success(customers, "Customers fetched");
    }

    /**
     * Send a WhatsApp offer to selected customers of this shop (marketing template).
     */
    @PostMapping("/customers/{shopId}/send-offer")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendOfferToCustomers(
            @PathVariable Long shopId,
            @RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked")
        List<Number> ids = (List<Number>) body.get("customerIds");
        String offerText = body.get("offerText") != null ? String.valueOf(body.get("offerText")) : null;
        String imageUrl = body.get("imageUrl") != null && !String.valueOf(body.get("imageUrl")).isBlank()
                ? String.valueOf(body.get("imageUrl")) : null;
        List<Long> customerIds = ids == null ? List.of() : ids.stream().map(Number::longValue).collect(Collectors.toList());
        log.info("Sending offer for shop {} to {} customers (image: {})", shopId, customerIds.size(), imageUrl != null);
        Map<String, Object> result = posService.sendOfferToCustomers(shopId, customerIds, offerText, imageUrl);
        return ResponseUtil.success(result, "Offer messages processed");
    }

    /**
     * Upload an image for a WhatsApp offer campaign; returns its public URL.
     */
    @PostMapping("/customers/{shopId}/offer-image")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadOfferImage(
            @PathVariable Long shopId,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        String url = posService.storeOfferImage(shopId, file);
        return ResponseUtil.success(Map.of("url", url), "Offer image uploaded");
    }

    /**
     * A customer's purchase history at this shop (orders with line items, most recent first).
     */
    @GetMapping("/customers/{shopId}/{customerId}/orders")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getCustomerOrderHistory(
            @PathVariable Long shopId,
            @PathVariable Long customerId) {
        List<Map<String, Object>> history = posService.getCustomerOrderHistory(shopId, customerId);
        return ResponseUtil.success(history, "Customer order history fetched");
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
        data.put("shopId", product.getShop() != null ? product.getShop().getId() : null);

        // Safe null handling for master product
        var masterProduct = product.getMasterProduct();
        if (masterProduct != null) {
            data.put("name", product.getCustomName() != null
                    ? product.getCustomName()
                    : masterProduct.getName());
            data.put("nameTamil", masterProduct.getNameTamil());
            data.put("sku", masterProduct.getSku());
            data.put("barcode", masterProduct.getBarcode());
            data.put("image", masterProduct.getPrimaryImageUrl());
            data.put("categoryId", masterProduct.getCategory() != null
                    ? masterProduct.getCategory().getId()
                    : null);
            data.put("categoryName", masterProduct.getCategory() != null
                    ? masterProduct.getCategory().getName()
                    : null);
            data.put("unit", masterProduct.getBaseUnit());
            data.put("weight", masterProduct.getBaseWeight());
        } else {
            data.put("name", product.getCustomName() != null ? product.getCustomName() : "Unknown");
            data.put("nameTamil", null);
            data.put("sku", null);
            data.put("barcode", null);
            data.put("image", null);
            data.put("categoryId", null);
            data.put("categoryName", null);
            data.put("unit", null);
            data.put("weight", null);
        }

        data.put("price", product.getPrice());
        data.put("stock", product.getStockQuantity());
        data.put("trackInventory", product.getTrackInventory());
        return data;
    }
}
