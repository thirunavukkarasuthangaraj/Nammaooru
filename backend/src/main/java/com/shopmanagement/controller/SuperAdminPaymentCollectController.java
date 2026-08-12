package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.ShopPaymentCollection;
import com.shopmanagement.entity.ShopPaymentPrice;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.ShopPaymentCollectService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/super-admin/payment-collect")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminPaymentCollectController {

    private final ShopPaymentCollectService shopPaymentCollectService;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<Map<String, Object>> shops = shopPaymentCollectService.listShopsWithStatus(pageable);
            return ResponseUtil.paginated(shops);
        } catch (Exception e) {
            log.error("Error listing shop payment status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{shopId}")
    public ResponseEntity<ApiResponse<ShopPaymentPrice>> setPrice(
            @PathVariable Long shopId,
            @RequestBody Map<String, Object> request) {
        try {
            int amount = ((Number) request.get("amount")).intValue();
            if (amount < 0) {
                return ResponseUtil.badRequest("amount must be zero or positive");
            }
            // Optional per-shop overrides; null/absent = global setting
            Integer durationDays = request.get("durationDays") != null
                    ? ((Number) request.get("durationDays")).intValue()
                    : null;
            Integer whatsappRatePaise = request.get("whatsappRatePaise") != null
                    ? ((Number) request.get("whatsappRatePaise")).intValue()
                    : null;
            Long adminUserId = getCurrentUser().getId();
            ShopPaymentPrice saved = shopPaymentCollectService.setPrice(shopId, amount, durationDays, whatsappRatePaise, adminUserId);
            return ResponseUtil.success(saved, "Price updated");
        } catch (Exception e) {
            log.error("Error setting shop payment price", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{shopId}/history")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHistory(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ShopPaymentCollection> history = shopPaymentCollectService.getHistory(shopId, pageable);
            return ResponseUtil.paginated(history);
        } catch (Exception e) {
            log.error("Error fetching shop payment history", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/duration")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDuration() {
        try {
            return ResponseUtil.success(Map.of("durationDays", shopPaymentCollectService.getDurationDays()));
        } catch (Exception e) {
            log.error("Error fetching duration setting", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/config")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBillingConfig() {
        try {
            return ResponseUtil.success(shopPaymentCollectService.getBillingConfig(), "Billing config retrieved");
        } catch (Exception e) {
            log.error("Error fetching billing config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/config")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateBillingConfig(@RequestBody Map<String, Object> request) {
        try {
            Integer billRate = request.get("billRatePaise") != null ? ((Number) request.get("billRatePaise")).intValue() : null;
            Integer marketingRate = request.get("marketingRatePaise") != null ? ((Number) request.get("marketingRatePaise")).intValue() : null;
            Integer gstPercent = request.get("gstPercent") != null ? ((Number) request.get("gstPercent")).intValue() : null;
            shopPaymentCollectService.updateBillingConfig(billRate, marketingRate, gstPercent);
            return ResponseUtil.success(shopPaymentCollectService.getBillingConfig(), "Billing config updated");
        } catch (Exception e) {
            log.error("Error updating billing config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/usage-summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUsageSummary() {
        try {
            return ResponseUtil.success(shopPaymentCollectService.getUsageSummary(), "Usage summary retrieved");
        } catch (Exception e) {
            log.error("Error fetching usage summary", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/duration")
    public ResponseEntity<ApiResponse<Map<String, Object>>> setDuration(@RequestBody Map<String, Object> request) {
        try {
            int days = ((Number) request.get("durationDays")).intValue();
            shopPaymentCollectService.setDurationDays(days);
            return ResponseUtil.success(Map.of("durationDays", days), "Duration updated");
        } catch (Exception e) {
            log.error("Error updating duration setting", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByUsername(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
