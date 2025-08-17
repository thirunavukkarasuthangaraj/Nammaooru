package com.shopmanagement.controller;

import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.entity.Order;
import com.shopmanagement.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody OrderRequest request) {
        log.info("Creating order for customer: {}", request.getCustomerId());
        OrderResponse response = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<OrderResponse> getOrderById(@PathVariable Long id) {
        log.info("Fetching order with ID: {}", id);
        OrderResponse response = orderService.getOrderById(id);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/number/{orderNumber}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<OrderResponse> getOrderByNumber(@PathVariable String orderNumber) {
        log.info("Fetching order with number: {}", orderNumber);
        OrderResponse response = orderService.getOrderByNumber(orderNumber);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<OrderResponse> updateOrderStatus(
            @PathVariable Long id,
            @RequestParam Order.OrderStatus status) {
        log.info("Updating order status: {} to {}", id, status);
        OrderResponse response = orderService.updateOrderStatus(id, status);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<OrderResponse> cancelOrder(
            @PathVariable Long id,
            @RequestParam String reason) {
        log.info("Cancelling order: {} with reason: {}", id, reason);
        OrderResponse response = orderService.cancelOrder(id, reason);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<OrderResponse>> getAllOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching all orders - page: {}, size: {}", page, size);
        Page<OrderResponse> response = orderService.getAllOrders(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<OrderResponse>> getOrdersByShop(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders for shop: {}", shopId);
        Page<OrderResponse> response = orderService.getOrdersByShop(shopId, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/customer/{customerId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('CUSTOMER')")
    public ResponseEntity<Page<OrderResponse>> getOrdersByCustomer(
            @PathVariable Long customerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders for customer: {}", customerId);
        Page<OrderResponse> response = orderService.getOrdersByCustomer(customerId, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<OrderResponse>> getOrdersByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching orders with status: {}", status);
        Order.OrderStatus orderStatus = Order.OrderStatus.valueOf(status.toUpperCase());
        Page<OrderResponse> response = orderService.getOrdersByStatus(orderStatus, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<OrderResponse>> searchOrders(
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching orders with term: {}", searchTerm);
        Page<OrderResponse> response = orderService.searchOrders(searchTerm, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/statuses")
    public ResponseEntity<Map<String, Object>> getOrderStatuses() {
        return ResponseEntity.ok(Map.of(
                "orderStatuses", Order.OrderStatus.values(),
                "paymentStatuses", Order.PaymentStatus.values(),
                "paymentMethods", Order.PaymentMethod.values()
        ));
    }
    
    @PostMapping("/{orderId}/accept")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<OrderResponse> acceptOrder(
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
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{orderId}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<OrderResponse> rejectOrder(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> requestBody) {
        log.info("Rejecting order: {}", orderId);
        
        String reason = requestBody.get("reason");
        if (reason == null || reason.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(null);
        }
        
        OrderResponse response = orderService.rejectOrder(orderId, reason);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{orderId}/tracking")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Map<String, Object>> getOrderTracking(@PathVariable Long orderId) {
        log.info("Fetching tracking information for order: {}", orderId);
        Map<String, Object> trackingInfo = orderService.getOrderTracking(orderId);
        return ResponseEntity.ok(trackingInfo);
    }
    
    @PostMapping("/{orderId}/ready")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<OrderResponse> markOrderReady(@PathVariable Long orderId) {
        log.info("Marking order ready: {}", orderId);
        OrderResponse response = orderService.updateOrderStatus(orderId, Order.OrderStatus.READY);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{orderId}/prepare")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<OrderResponse> startPreparingOrder(@PathVariable Long orderId) {
        log.info("Starting preparation for order: {}", orderId);
        OrderResponse response = orderService.updateOrderStatus(orderId, Order.OrderStatus.PREPARING);
        return ResponseEntity.ok(response);
    }
}