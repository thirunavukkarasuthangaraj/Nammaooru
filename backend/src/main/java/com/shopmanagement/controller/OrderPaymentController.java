package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.OrderPayment;
import com.shopmanagement.service.OrderPaymentService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.io.BufferedReader;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class OrderPaymentController {

    private final OrderPaymentService orderPaymentService;
    private final ShopService shopService;

    @PostMapping("/customer/orders/{orderId}/payment/create-order")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createOrder(
            @PathVariable Long orderId, Authentication authentication) {
        try {
            Map<String, Object> result = orderPaymentService.createOrder(orderId, authentication);
            return ResponseUtil.success(result, "Payment order created");
        } catch (Exception e) {
            log.error("Error creating order payment for order {}", orderId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/customer/orders/{orderId}/payment/verify")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPayment(
            @PathVariable Long orderId, Authentication authentication,
            @RequestBody Map<String, String> request) {
        try {
            String razorpayOrderId = request.get("razorpay_order_id");
            String paymentId = request.get("razorpay_payment_id");
            String signature = request.get("razorpay_signature");
            if (razorpayOrderId == null || paymentId == null) {
                return ResponseUtil.badRequest("razorpay_order_id and razorpay_payment_id are required");
            }
            OrderPayment payment = orderPaymentService.verifyPayment(razorpayOrderId, paymentId, signature, authentication);
            return ResponseUtil.success(Map.of("status", payment.getStatus().name()), "Payment verified");
        } catch (Exception e) {
            log.error("Error verifying order payment for order {}", orderId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Razorpay calls this directly (no user session) — the webhook signature itself,
     * verified inside handleWebhook against the configured secret, is the auth here.
     */
    @PostMapping("/order-payments/webhook")
    public ResponseEntity<String> webhook(HttpServletRequest request,
                                           @RequestHeader(value = "X-Razorpay-Signature", required = false) String signature) {
        try {
            StringBuilder body = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    body.append(line);
                }
            }
            orderPaymentService.handleWebhook(body.toString(), signature);
            return ResponseEntity.ok("OK");
        } catch (Exception e) {
            log.error("Error handling Razorpay webhook", e);
            // Still 200 — Razorpay retries on non-2xx, and a body/parsing error won't fix
            // itself on retry. We've logged it for manual follow-up instead.
            return ResponseEntity.ok("ERROR");
        }
    }

    /**
     * Lets the checkout screen show the gateway fee before the order is placed —
     * the percent itself isn't sensitive, just the admin ability to change it.
     */
    @GetMapping("/customer/order-payments/config")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCustomerConfig() {
        try {
            return ResponseUtil.success(Map.of("gatewayFeePercent", orderPaymentService.getGatewayFeePercent()), "Config retrieved");
        } catch (Exception e) {
            log.error("Error getting order payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/order-payments/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getConfig() {
        try {
            return ResponseUtil.success(Map.of("gatewayFeePercent", orderPaymentService.getGatewayFeePercent()), "Config retrieved");
        } catch (Exception e) {
            log.error("Error getting order payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/order-payments/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> updateConfig(@RequestBody Map<String, String> body) {
        try {
            if (body.get("gatewayFeePercent") != null) {
                orderPaymentService.setGatewayFeePercent(new java.math.BigDecimal(body.get("gatewayFeePercent")));
            }
            return ResponseUtil.success(null, "Config updated");
        } catch (Exception e) {
            log.error("Error updating order payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * The transaction-level view for a shop owner's own Payments screen -
     * amount, gateway fee, and status (paid/failed/refunded) per order, as
     * opposed to the wallet ledger which only has entries for settled
     * (delivered) online orders.
     */
    @GetMapping("/order-payments/shop/transactions")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listForShop(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Shop shop = shopService.getShopByOwner(authentication.getName());
            if (shop == null) {
                return ResponseUtil.error("Shop not found for owner: " + authentication.getName());
            }
            Pageable pageable = PageRequest.of(page, size);
            Page<Map<String, Object>> payments = orderPaymentService.listForShop(shop.getId(), pageable);
            return ResponseUtil.paginated(payments);
        } catch (Exception e) {
            log.error("Error listing shop order payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/order-payments/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<OrderPayment> payments = orderPaymentService.listAll(pageable);
            return ResponseUtil.paginated(payments);
        } catch (Exception e) {
            log.error("Error listing order payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
