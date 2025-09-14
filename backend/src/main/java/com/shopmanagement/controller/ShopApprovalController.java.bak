package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.shop.dto.ShopPageResponse;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.entity.ShopDocument;
import com.shopmanagement.shop.service.ShopService;
import com.shopmanagement.shop.service.ShopDocumentService;
import com.shopmanagement.shop.dto.ShopDocumentResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shops/approvals")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN')")
public class ShopApprovalController {

    private final ShopService shopService;
    private final ShopDocumentService shopDocumentService;

    @GetMapping
    public ResponseEntity<ApiResponse<ShopPageResponse>> getPendingShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String businessType) {
        
        log.info("Fetching shops for approval - page: {}, size: {}, status: {}, search: {}, businessType: {}", 
                 page, size, status, search, businessType);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<ShopResponse> shopsPage;
        
        // If no status filter is provided, get all shops. Otherwise filter by status
        if (status == null || status.trim().isEmpty()) {
            shopsPage = shopService.getAllShops(pageable);
        } else {
            try {
                Shop.ShopStatus shopStatus = Shop.ShopStatus.valueOf(status.toUpperCase());
                shopsPage = shopService.getShopsByStatus(shopStatus, pageable);
            } catch (IllegalArgumentException e) {
                log.warn("Invalid shop status provided: {}", status);
                // Default to all shops if invalid status
                shopsPage = shopService.getAllShops(pageable);
            }
        }
        
        ShopPageResponse response = ShopPageResponse.builder()
                .content(shopsPage.getContent())
                .page(shopsPage.getNumber())
                .size(shopsPage.getSize())
                .totalElements(shopsPage.getTotalElements())
                .totalPages(shopsPage.getTotalPages())
                .first(shopsPage.isFirst())
                .last(shopsPage.isLast())
                .hasNext(shopsPage.hasNext())
                .hasPrevious(shopsPage.hasPrevious())
                .build();
        
        String message = (status == null || status.trim().isEmpty()) 
            ? "All shops fetched successfully" 
            : String.format("%s shops fetched successfully", status.toLowerCase());
        
        return ResponseEntity.ok(ApiResponse.success(response, message));
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
    public ResponseEntity<ApiResponse<ShopPageResponse>> getApprovalHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Shop.ShopStatus status) {
        
        log.info("Fetching approval history - page: {}, size: {}, status: {}", page, size, status);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "updatedAt"));
        
        Page<ShopResponse> approvalHistoryPage;
        if (status != null) {
            approvalHistoryPage = shopService.getShopsByStatus(status, pageable);
        } else {
            approvalHistoryPage = shopService.getAllShops(pageable);
        }
        
        ShopPageResponse response = ShopPageResponse.builder()
                .content(approvalHistoryPage.getContent())
                .page(approvalHistoryPage.getNumber())
                .size(approvalHistoryPage.getSize())
                .totalElements(approvalHistoryPage.getTotalElements())
                .totalPages(approvalHistoryPage.getTotalPages())
                .first(approvalHistoryPage.isFirst())
                .last(approvalHistoryPage.isLast())
                .hasNext(approvalHistoryPage.hasNext())
                .hasPrevious(approvalHistoryPage.hasPrevious())
                .build();
        
        return ResponseEntity.ok(ApiResponse.success(
                response,
                "Approval history fetched successfully"
        ));
    }

    @GetMapping("/{shopId}/documents")
    public ResponseEntity<ApiResponse<List<ShopDocumentResponse>>> getShopDocuments(@PathVariable Long shopId) {
        log.info("Fetching documents for shop: {}", shopId);
        
        List<ShopDocumentResponse> documents = shopDocumentService.getShopDocuments(shopId);
        
        return ResponseEntity.ok(ApiResponse.success(
                documents,
                "Shop documents fetched successfully"
        ));
    }

    @GetMapping("/{shopId}/documents/verification-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDocumentVerificationStatus(@PathVariable Long shopId) {
        log.info("Fetching document verification status for shop: {}", shopId);
        
        List<ShopDocumentResponse> documents = shopDocumentService.getShopDocuments(shopId);
        
        long totalDocuments = documents.size();
        long verifiedDocuments = documents.stream()
                .filter(doc -> doc.getVerificationStatus() == ShopDocument.VerificationStatus.VERIFIED)
                .count();
        long rejectedDocuments = documents.stream()
                .filter(doc -> doc.getVerificationStatus() == ShopDocument.VerificationStatus.REJECTED)
                .count();
        long pendingDocuments = documents.stream()
                .filter(doc -> doc.getVerificationStatus() == ShopDocument.VerificationStatus.PENDING)
                .count();

        Map<String, Object> status = Map.of(
                "totalDocuments", totalDocuments,
                "verifiedDocuments", verifiedDocuments,
                "rejectedDocuments", rejectedDocuments,
                "pendingDocuments", pendingDocuments,
                "allDocumentsVerified", totalDocuments > 0 && verifiedDocuments == totalDocuments,
                "hasRejectedDocuments", rejectedDocuments > 0,
                "documents", documents
        );
        
        return ResponseEntity.ok(ApiResponse.success(
                status,
                "Document verification status fetched successfully"
        ));
    }
}