package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.PosOrderRequest;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.service.PosService;
import com.shopmanagement.service.BillSettingsService;
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
    private final BillSettingsService billSettingsService;

    @GetMapping("/shops/{shopId}/bill-settings")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBillSettings(@PathVariable Long shopId) {
        return ResponseUtil.success(billSettingsService.getForCurrentUser(shopId), "Bill settings loaded");
    }

    @PutMapping("/shops/{shopId}/bill-settings")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> saveBillSettings(
            @PathVariable Long shopId, @RequestBody Map<String, Object> settings) {
        return ResponseUtil.success(billSettingsService.saveForCurrentUser(shopId, settings), "Bill settings saved");
    }

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
     * Append items to an existing POS order (e.g. cashier printed, then noticed
     * a missed item) instead of creating a brand-new bill/order number.
     */
    @PutMapping("/orders/{orderId}/items")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> addItemsToOrder(
            @PathVariable Long orderId,
            @Valid @RequestBody List<com.shopmanagement.dto.order.PosOrderItemRequest> items) {
        log.info("Appending {} item(s) to POS order {}", items.size(), orderId);
        OrderResponse response = posService.addItemsToOrder(orderId, items);
        return ResponseUtil.success(response, "Items added to bill successfully");
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
     * Generate the bill (image + PDF) and return the public links WITHOUT
     * sending any message — the shop owner shares them from their own WhatsApp
     * (wa.me) so the customer receives the bill from the shop's number.
     */
    @PostMapping("/orders/{orderId}/bill-link")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, String>>> getBillShareLinks(@PathVariable Long orderId) {
        log.info("Generating bill share links for order: {}", orderId);
        return ResponseUtil.success(posService.getBillShareLinks(orderId), "Bill links generated");
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
     * Update a customer's name/phone from the shop owner's customer list.
     */
    @PutMapping("/customers/{shopId}/{customerId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateShopCustomer(
            @PathVariable Long shopId,
            @PathVariable Long customerId,
            @RequestBody Map<String, String> body) {
        log.info("Updating customer {} for shop {}", customerId, shopId);
        Map<String, Object> result = posService.updateShopCustomer(
                shopId, customerId, body.get("name"), body.get("phone"));
        return ResponseUtil.success(result, "Customer updated");
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
            data.put("sku", com.shopmanagement.common.util.SkuUtil.displaySku(masterProduct.getSku()));
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
