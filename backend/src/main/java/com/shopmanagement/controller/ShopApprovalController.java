package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.shop.dto.ShopResponse;
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
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/shops/approvals")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN')")
public class ShopApprovalController {

    private final ShopService shopService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ShopResponse>>> getPendingShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching pending shops for approval - page: {}, size: {}", page, size);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<ShopResponse> pendingShops = shopService.getShopsByStatus(Shop.ShopStatus.PENDING, pageable);
        
        return ResponseEntity.ok(ApiResponse.success(
                pendingShops,
                "Pending shops fetched successfully"
        ));
    }

    @PutMapping("/{shopId}/approve")
    public ResponseEntity<ApiResponse<ShopResponse>> approveShop(
            @PathVariable Long shopId,
            @RequestBody(required = false) Map<String, String> requestBody) {
        
        String approvalNotes = requestBody != null ? requestBody.get("notes") : null;
        log.info("Approving shop: {} with notes: {}", shopId, approvalNotes);
        
        ShopResponse approvedShop = shopService.approveShop(shopId, approvalNotes);
        
        return ResponseEntity.ok(ApiResponse.success(
                approvedShop,
                "Shop approved successfully"
        ));
    }

    @PutMapping("/{shopId}/reject")
    public ResponseEntity<ApiResponse<ShopResponse>> rejectShop(
            @PathVariable Long shopId,
            @RequestBody Map<String, String> requestBody) {
        
        String rejectionReason = requestBody.get("reason");
        if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error(
                    "INVALID_REQUEST", "Rejection reason is required"
            ));
        }
        
        log.info("Rejecting shop: {} with reason: {}", shopId, rejectionReason);
        
        ShopResponse rejectedShop = shopService.rejectShop(shopId, rejectionReason);
        
        return ResponseEntity.ok(ApiResponse.success(
                rejectedShop,
                "Shop rejected successfully"
        ));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovalStats() {
        log.info("Fetching shop approval statistics");
        
        Map<String, Object> stats = shopService.getApprovalStats();
        
        return ResponseEntity.ok(ApiResponse.success(
                stats,
                "Approval statistics fetched successfully"
        ));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<Page<ShopResponse>>> getApprovalHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Shop.ShopStatus status) {
        
        log.info("Fetching approval history - page: {}, size: {}, status: {}", page, size, status);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "updatedAt"));
        
        Page<ShopResponse> approvalHistory;
        if (status != null) {
            approvalHistory = shopService.getShopsByStatus(status, pageable);
        } else {
            approvalHistory = shopService.getAllShops(null, pageable);
        }
        
        return ResponseEntity.ok(ApiResponse.success(
                approvalHistory,
                "Approval history fetched successfully"
        ));
    }
}