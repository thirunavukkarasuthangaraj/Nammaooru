package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.entity.Order;
import com.shopmanagement.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Slf4j
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<OrderResponse>> createOrder(@RequestBody OrderRequest request) {
        log.info("Creating order for customer: {} or user: {}", request.getCustomerId(), request.getUserId());
        // Bypass validation - let OrderService handle customer/user logic
        OrderResponse response = orderService.createOrder(request);
        return ResponseUtil.created(response, "Order created successfully");
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(@PathVariable Long id) {
        log.info("Fetching order with ID: {}", id);
        OrderResponse response = orderService.getOrderById(id);
        return ResponseUtil.success(response, "Order retrieved successfully");
    }
    
    @GetMapping("/number/{orderNumber}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderByNumber(@PathVariable String orderNumber) {
        log.info("Fetching order with number: {}", orderNumber);
        OrderResponse response = orderService.getOrderByNumber(orderNumber);
        return ResponseUtil.success(response, "Order retrieved successfully");
    }
    
    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> updateOrderStatus(
            @PathVariable Long id,
            @RequestParam Order.OrderStatus status) {
        log.info("Updating order status: {} to {}", id, status);
        OrderResponse response = orderService.updateOrderStatus(id, status);
        return ResponseUtil.success(response, "Order status updated successfully");
    }
    
    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrder(
            @PathVariable Long id,
            @RequestParam String reason) {
        log.info("Cancelling order: {} with reason: {}", id, reason);
        OrderResponse response = orderService.cancelOrder(id, reason);
        return ResponseUtil.success(response, "Order cancelled successfully");
    }
    
    @GetMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching all orders - page: {}, size: {}", page, size);
        Page<OrderResponse> response = orderService.getAllOrders(page, size, sortBy, sortDirection);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOrdersByShop(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders for shop: {}", shopId);
        Page<OrderResponse> response = orderService.getOrdersByShop(shopId, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/customer/{customerId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOrdersByCustomer(
            @PathVariable Long customerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders for customer: {}", customerId);
        Page<OrderResponse> response = orderService.getOrdersByCustomer(customerId, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOrdersByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders with status: {}", status);
        Order.OrderStatus orderStatus = Order.OrderStatus.valueOf(status.toUpperCase());
        Page<OrderResponse> response = orderService.getOrdersByStatus(orderStatus, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> searchOrders(
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching orders with term: {}", searchTerm);
        Page<OrderResponse> response = orderService.searchOrders(searchTerm, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/statuses")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOrderStatuses() {
        Map<String, Object> data = Map.of(
                "orderStatuses", Order.OrderStatus.values(),
                "paymentStatuses", Order.PaymentStatus.values(),
                "paymentMethods", Order.PaymentMethod.values()
        );
        return ResponseUtil.success(data, "Order statuses retrieved successfully");
    }
    
    @PostMapping("/{orderId}/accept")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> acceptOrder(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, Object> requestBody) {
        log.info("Accepting order: {}", orderId);
        
        String estimatedPreparationTime = null;
        String notes = null;
        
        if (requestBody != null) {
            estimatedPreparationTime = (String) requestBody.get("estimatedPreparationTime");
            notes = (String) requestBody.get("notes");
        }
        
        OrderResponse response = orderService.acceptOrder(orderId, estimatedPreparationTime, notes);
        return ResponseUtil.success(response, "Order accepted successfully");
    }
    
    @PostMapping("/{orderId}/reject")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> rejectOrder(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> requestBody) {
        log.info("Rejecting order: {}", orderId);
        
        String reason = requestBody.get("reason");
        if (reason == null || reason.trim().isEmpty()) {
            return ResponseUtil.badRequest("Rejection reason is required");
        }
        
        OrderResponse response = orderService.rejectOrder(orderId, reason);
        return ResponseUtil.success(response, "Order rejected successfully");
    }
    
    @GetMapping("/{orderId}/tracking")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOrderTracking(@PathVariable Long orderId) {
        log.info("Fetching tracking information for order: {}", orderId);
        Map<String, Object> trackingInfo = orderService.getOrderTracking(orderId);
        return ResponseUtil.success(trackingInfo, "Order tracking retrieved successfully");
    }
    
    @PostMapping("/{orderId}/ready")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> markOrderReady(@PathVariable Long orderId) {
        log.info("Marking order ready: {}", orderId);
        OrderResponse response = orderService.updateOrderStatus(orderId, Order.OrderStatus.READY_FOR_PICKUP);
        return ResponseUtil.success(response, "Order marked as ready successfully");
    }
    
    @PostMapping("/{orderId}/prepare")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> startPreparingOrder(@PathVariable Long orderId) {
        log.info("Starting preparation for order: {}", orderId);
        OrderResponse response = orderService.updateOrderStatus(orderId, Order.OrderStatus.PREPARING);
        return ResponseUtil.success(response, "Order preparation started successfully");
    }
}