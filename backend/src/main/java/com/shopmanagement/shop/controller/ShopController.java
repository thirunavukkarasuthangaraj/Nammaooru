package com.shopmanagement.shop.controller;

import com.shopmanagement.common.constants.ResponseConstants;
import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.shop.dto.ShopCreateRequest;
import com.shopmanagement.shop.dto.ShopPageResponse;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.dto.ShopUpdateRequest;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import com.shopmanagement.shop.specification.ShopSpecification;
import com.shopmanagement.service.OrderService;
import com.shopmanagement.dto.order.OrderResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shops")
@RequiredArgsConstructor
@Slf4j
public class ShopController {

    private final ShopService shopService;
    private final OrderService orderService;

    @PostMapping
    // @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')") // TEMPORARY: Commented out for testing
    public ResponseEntity<ApiResponse<ShopResponse>> createShop(@Valid @RequestBody ShopCreateRequest request) {
        log.info("Creating new shop: {}", request.getName());
        ShopResponse response = shopService.createShop(request);
        return ResponseUtil.created(response, "Shop created successfully");
    }

    @GetMapping
    public ResponseEntity<ApiResponse<ShopPageResponse>> getAllShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String state,
            @RequestParam(required = false) String businessType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) Boolean isVerified,
            @RequestParam(required = false) Boolean isFeatured,
            @RequestParam(required = false) BigDecimal minRating,
            @RequestParam(required = false) BigDecimal maxRating,
            @RequestParam(required = false) String search) {
        
        Sort sort = Sort.by(sortDir.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC, sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        
        Specification<Shop> spec = ShopSpecification.withFilters(
            name, city, state, businessType, status, isActive, isVerified, isFeatured, minRating, maxRating, search
        );
        
        Page<ShopResponse> shopPage = shopService.filterShops(spec, pageable);
        
        ShopPageResponse response = ShopPageResponse.builder()
                .content(shopPage.getContent())
                .page(shopPage.getNumber())
                .size(shopPage.getSize())
                .totalElements(shopPage.getTotalElements())
                .totalPages(shopPage.getTotalPages())
                .first(shopPage.isFirst())
                .last(shopPage.isLast())
                .hasNext(shopPage.hasNext())
                .hasPrevious(shopPage.hasPrevious())
                .build();
        
        return ResponseUtil.success(response, "Shops retrieved successfully");
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<ShopPageResponse>> getActiveShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {
        
        Sort sort = Sort.by(sortDir.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC, sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        
        Page<ShopResponse> shopPage = shopService.getActiveShops(pageable);
        
        ShopPageResponse response = ShopPageResponse.builder()
                .content(shopPage.getContent())
                .page(shopPage.getNumber())
                .size(shopPage.getSize())
                .totalElements(shopPage.getTotalElements())
                .totalPages(shopPage.getTotalPages())
                .first(shopPage.isFirst())
                .last(shopPage.isLast())
                .hasNext(shopPage.hasNext())
                .hasPrevious(shopPage.hasPrevious())
                .build();
        
        return ResponseUtil.success(response, "Active shops retrieved successfully");
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<ShopPageResponse>> searchShops(
            @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {
        
        if (q == null || q.trim().isEmpty()) {
            return ResponseUtil.badRequest("Search query cannot be empty");
        }
        
        Sort sort = Sort.by(sortDir.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC, sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        
        Page<ShopResponse> shopPage = shopService.searchShops(q, pageable);
        
        ShopPageResponse response = ShopPageResponse.builder()
                .content(shopPage.getContent())
                .page(shopPage.getNumber())
                .size(shopPage.getSize())
                .totalElements(shopPage.getTotalElements())
                .totalPages(shopPage.getTotalPages())
                .first(shopPage.isFirst())
                .last(shopPage.isLast())
                .hasNext(shopPage.hasNext())
                .hasPrevious(shopPage.hasPrevious())
                .build();
        
        return ResponseUtil.success(response, "Search completed successfully");
    }

    @GetMapping("/nearby")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getNearbyShops(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "10.0") double radius) {

        List<ShopResponse> nearbyShops = shopService.getNearbyShops(lat, lng, radius);

        Map<String, Object> response = new HashMap<>();
        response.put("shops", nearbyShops);
        response.put("count", nearbyShops.size());
        response.put("radius", radius);
        response.put("latitude", lat);
        response.put("longitude", lng);

        return ResponseUtil.success(response, "Nearby shops retrieved successfully");
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFeaturedShops() {
        List<ShopResponse> featuredShops = shopService.getFeaturedShops();

        Map<String, Object> response = new HashMap<>();
        response.put("shops", featuredShops);
        response.put("count", featuredShops.size());

        return ResponseUtil.success(response, "Featured shops retrieved successfully");
    }

    @GetMapping("/my-shop")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ShopResponse>> getMyShop(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseUtil.unauthorized();
        }

        String username = authentication.getName();
        log.info("Getting shop for user: {}", username);

        try {
            ShopResponse shop = shopService.getShopByOwnerUsername(username);
            if (shop == null) {
                return ResponseUtil.notFound("No shop found for this user");
            }
            return ResponseUtil.success(shop, "Shop retrieved successfully");
        } catch (Exception e) {
            log.error("Error getting shop for user {}: {}", username, e.getMessage());
            return ResponseUtil.error("Failed to get shop: " + e.getMessage());
        }
    }

    @GetMapping("/approvals")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ShopPageResponse>> getShopsAwaitingApproval(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            @RequestParam(required = false) String status) {

        Sort sort = Sort.by(sortDir.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC, sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<ShopResponse> shopPage;
        if (status != null && !status.isEmpty()) {
            // If status is specified, get shops with that status
            Shop.ShopStatus shopStatus = Shop.ShopStatus.valueOf(status.toUpperCase());
            shopPage = shopService.getShopsByStatus(shopStatus, pageable);
        } else {
            // Default: get all shops for approval review (PENDING, APPROVED, REJECTED)
            shopPage = shopService.getAllShopsForApproval(pageable);
        }

        ShopPageResponse response = ShopPageResponse.builder()
                .content(shopPage.getContent())
                .page(shopPage.getNumber())
                .size(shopPage.getSize())
                .totalElements(shopPage.getTotalElements())
                .totalPages(shopPage.getTotalPages())
                .first(shopPage.isFirst())
                .last(shopPage.isLast())
                .build();

        return ResponseUtil.success(response, "Shops for approval retrieved successfully");
    }

    @GetMapping("/approvals/stats")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovalStats() {
        Map<String, Object> stats = new HashMap<>();

        // Get counts for different approval statuses
        long pendingCount = shopService.countShopsByStatus(Shop.ShopStatus.PENDING);
        long approvedCount = shopService.countShopsByStatus(Shop.ShopStatus.APPROVED);
        long rejectedCount = shopService.countShopsByStatus(Shop.ShopStatus.REJECTED);

        stats.put("pending", pendingCount);
        stats.put("approved", approvedCount);
        stats.put("rejected", rejectedCount);
        stats.put("total", pendingCount + approvedCount + rejectedCount);

        return ResponseUtil.success(stats, "Approval statistics retrieved successfully");
    }

    @GetMapping("/approvals/{shopId}/documents/verification-status")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDocumentVerificationStatus(@PathVariable Long shopId) {
        log.info("Getting document verification status for shop: {}", shopId);

        try {
            Map<String, Object> verificationStatus = shopService.getDocumentVerificationStatus(shopId);
            return ResponseUtil.success(verificationStatus, "Document verification status retrieved successfully");
        } catch (RuntimeException e) {
            log.error("Error getting verification status for shop {}: {}", shopId, e.getMessage());
            return ResponseUtil.error("Shop not found or verification status unavailable");
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ShopResponse>> getShopById(@PathVariable Long id) {
        log.info("Fetching shop with ID: {}", id);
        ShopResponse response = shopService.getShopById(id);
        return ResponseUtil.success(response, "Shop details retrieved successfully");
    }

    @GetMapping("/shop-id/{shopId}")
    public ResponseEntity<ApiResponse<ShopResponse>> getShopByShopId(@PathVariable String shopId) {
        log.info("Fetching shop with Shop ID: {}", shopId);
        ShopResponse response = shopService.getShopByShopId(shopId);
        return ResponseUtil.success(response, "Shop details retrieved successfully");
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<ApiResponse<ShopResponse>> getShopBySlug(@PathVariable String slug) {
        log.info("Fetching shop with slug: {}", slug);
        ShopResponse response = shopService.getShopBySlug(slug);
        return ResponseUtil.success(response, "Shop details retrieved successfully");
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<ShopResponse>> updateShop(
            @PathVariable Long id,
            @Valid @RequestBody ShopUpdateRequest request) {
        log.info("Updating shop with ID: {}", id);
        ShopResponse response = shopService.updateShop(id, request);
        return ResponseUtil.updated(response);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deleteShop(@PathVariable Long id) {
        log.info("Deleting shop with ID: {}", id);
        shopService.deleteShop(id);
        
        Map<String, Object> response = new HashMap<>();
        response.put("id", id);
        response.put("deleted", true);
        
        return ResponseUtil.success(response, "Shop deleted successfully");
    }

    @PutMapping("/{id}/approve")
    // @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')") // TEMPORARY: Commented out for testing
    public ResponseEntity<ApiResponse<ShopResponse>> approveShop(@PathVariable Long id) {
        log.info("Approving shop with ID: {}", id);
        ShopResponse response = shopService.approveShop(id);
        return ResponseUtil.success(response, "Shop approved successfully");
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ShopResponse>> rejectShop(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> requestBody) {
        log.info("Rejecting shop with ID: {}", id);
        String reason = requestBody != null ? requestBody.get("reason") : "Not meeting requirements";
        ShopResponse response = shopService.rejectShop(id);
        return ResponseUtil.success(response, "Shop rejected successfully");
    }

    @PutMapping("/{id}/suspend")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ShopResponse>> suspendShop(@PathVariable Long id) {
        log.info("Suspending shop with ID: {}", id);
        ShopResponse response = shopService.suspendShop(id);
        return ResponseUtil.success(response, "Shop suspended successfully");
    }

    @GetMapping("/cities")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCities() {
        // Return static list of Indian cities
        List<String> cities = List.of(
            "Chennai",
            "Bangalore", 
            "Mumbai",
            "New Delhi",
            "Hyderabad",
            "Pune",
            "Kolkata",
            "Ahmedabad",
            "Jaipur",
            "Coimbatore",
            "Chandigarh",
            "Lucknow",
            "Kochi",
            "Surat",
            "Nagpur",
            "Indore",
            "Thane",
            "Bhopal",
            "Visakhapatnam",
            "Vadodara",
            "Gurgaon",
            "Noida",
            "Mysore",
            "Trichy",
            "Salem"
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("cities", cities);
        response.put("count", cities.size());
        
        return ResponseUtil.success(response, "Cities retrieved successfully");
    }

    @GetMapping("/statistics")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopStatistics() {
        log.info("Fetching shop statistics");
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalShops", shopService.getTotalShopsCount());
        stats.put("activeShops", shopService.getActiveShopsCount());
        stats.put("pendingApproval", shopService.getPendingShopsCount());
        stats.put("rejectedShops", shopService.getRejectedShopsCount());
        stats.put("suspendedShops", shopService.getSuspendedShopsCount());
        
        return ResponseUtil.success(stats, "Statistics retrieved successfully");
    }

    @GetMapping("/{shopId}/dashboard")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopDashboard(@PathVariable String shopId) {
        log.info("Fetching dashboard data for shop: {}", shopId);
        Map<String, Object> dashboardData = shopService.getShopDashboard(shopId);
        return ResponseUtil.success(dashboardData, "Shop dashboard data retrieved successfully");
    }

    @GetMapping("/{shopId}/orders")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopOrders(
            @PathVariable String shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String dateFrom,
            @RequestParam(required = false) String dateTo) {
        
        log.info("Fetching orders for shop: {} with filters - status: {}, dateFrom: {}, dateTo: {}", 
                shopId, status, dateFrom, dateTo);
        
        Sort sort = Sort.by(sortDir.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC, sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        
        Map<String, Object> ordersData = shopService.getShopOrders(shopId, pageable, status, dateFrom, dateTo);
        return ResponseUtil.success(ordersData, "Shop orders retrieved successfully");
    }

    @GetMapping("/{shopId}/analytics")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopAnalytics(
            @PathVariable String shopId,
            @RequestParam(defaultValue = "30") int days) {

        log.info("Fetching analytics for shop: {} for {} days", shopId, days);
        Map<String, Object> analytics = shopService.getShopAnalytics(shopId, days);
        return ResponseUtil.success(analytics, "Shop analytics retrieved successfully");
    }

    @PostMapping("/orders/{orderId}/accept")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<OrderResponse>> acceptOrder(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> request) {

        String estimatedPreparationTime = request != null ? request.get("estimatedPreparationTime") : null;
        String notes = request != null ? request.get("notes") : null;

        log.info("Shop accepting order: {} with estimated preparation time: {}", orderId, estimatedPreparationTime);
        OrderResponse response = orderService.acceptOrder(orderId, estimatedPreparationTime, notes);
        return ResponseUtil.success(response, "Order accepted successfully");
    }

    @PostMapping("/orders/{orderId}/reject")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<OrderResponse>> rejectOrder(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> request) {

        String reason = request != null ? request.get("reason") : "Order rejected by shop";

        log.info("Shop rejecting order: {} with reason: {}", orderId, reason);
        OrderResponse response = orderService.rejectOrder(orderId, reason);
        return ResponseUtil.success(response, "Order rejected successfully");
    }

    @PostMapping("/orders/{orderNumber}/find-driver")
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> findDriverForOrder(
            @PathVariable String orderNumber) {

        log.info("Shop requesting to find driver for order: {}", orderNumber);
        Map<String, Object> result = shopService.findDriverForOrder(orderNumber);

        if ((Boolean) result.get("success")) {
            return ResponseUtil.success(result, "Driver assigned successfully");
        } else {
            return ResponseUtil.success(result, (String) result.get("message"));
        }
    }
}