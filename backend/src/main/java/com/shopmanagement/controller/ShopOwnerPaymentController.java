package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.ShopPaymentCollection;
import com.shopmanagement.service.ShopPaymentCollectService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/shop-owner-payments")
@RequiredArgsConstructor
@Slf4j
public class ShopOwnerPaymentController {

    private final ShopPaymentCollectService shopPaymentCollectService;
    private final ShopService shopService;

    @GetMapping("/status")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStatus(Authentication authentication) {
        try {
            Shop shop = requireShop(authentication);
            Map<String, Object> status = shopPaymentCollectService.getStatusForShop(shop.getId(), shop.getName());
            return ResponseUtil.success(status, "Payment status retrieved");
        } catch (Exception e) {
            log.error("Error getting shop payment status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/create-order")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createOrder(Authentication authentication) {
        try {
            Shop shop = requireShop(authentication);
            Map<String, Object> order = shopPaymentCollectService.createOrder(shop.getId());
            return ResponseUtil.success(order, "Order created");
        } catch (Exception e) {
            log.error("Error creating shop payment order", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/verify")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPayment(
            Authentication authentication,
            @RequestBody Map<String, String> request) {
        try {
            Shop shop = requireShop(authentication);
            String orderId = request.get("razorpay_order_id");
            String paymentId = request.get("razorpay_payment_id");
            String signature = request.get("razorpay_signature");

            if (orderId == null || paymentId == null || signature == null) {
                return ResponseUtil.badRequest("razorpay_order_id, razorpay_payment_id, and razorpay_signature are required");
            }

            // Ownership is checked inside verifyPayment before any status/validUntil mutation happens
            ShopPaymentCollection collection = shopPaymentCollectService.verifyPayment(shop.getId(), orderId, paymentId, signature);

            Map<String, Object> result = Map.of(
                    "status", collection.getStatus().name(),
                    "validUntil", collection.getValidUntil()
            );
            return ResponseUtil.success(result, "Payment verified successfully");
        } catch (Exception e) {
            log.error("Error verifying shop payment", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Shop requireShop(Authentication authentication) {
        String username = authentication.getName();
        Shop shop = shopService.getShopByOwner(username);
        if (shop == null) {
            throw new RuntimeException("Shop not found for owner: " + username);
        }
        return shop;
    }
}
