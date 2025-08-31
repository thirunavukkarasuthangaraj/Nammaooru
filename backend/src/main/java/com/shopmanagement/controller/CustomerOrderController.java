package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.order.CustomerOrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.OrderTrackingResponse;
import com.shopmanagement.service.OrderService;
import com.shopmanagement.service.FirebaseNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerOrderController {

    private final OrderService orderService;
    private final FirebaseNotificationService firebaseNotificationService;

    @PostMapping("/orders")
    public ResponseEntity<ApiResponse<OrderResponse>> createOrder(@RequestBody CustomerOrderRequest orderRequest) {
        try {
            log.info("Creating order for customer with shop ID: {}", orderRequest.getShopId());
            
            OrderResponse order = orderService.createCustomerOrder(orderRequest);
            
            // Send Firebase notification if customer token is available
            if (orderRequest.getCustomerToken() != null && !orderRequest.getCustomerToken().isEmpty()) {
                firebaseNotificationService.sendOrderNotification(
                    order.getOrderNumber(), 
                    "PLACED", 
                    orderRequest.getCustomerToken()
                );
            }
            
            return ResponseUtil.success(order, "Order created successfully");
            
        } catch (Exception e) {
            log.error("Error creating customer order", e);
            return ResponseUtil.error("Failed to create order");
        }
    }

    @GetMapping("/orders/{orderNumber}/tracking")
    public ResponseEntity<ApiResponse<OrderTrackingResponse>> getOrderTracking(@PathVariable String orderNumber) {
        try {
            log.info("Getting tracking info for order: {}", orderNumber);
            
            OrderTrackingResponse tracking = orderService.getOrderTracking(orderNumber);
            
            return ResponseUtil.success(tracking, "Order tracking retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving order tracking for: {}", orderNumber, e);
            return ResponseUtil.error("Order tracking not found");
        }
    }

    @GetMapping("/orders")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getMyOrders(
            @RequestParam(required = false) Long customerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            log.info("Getting orders for customer ID: {}", customerId);
            
            List<OrderResponse> orders = orderService.getCustomerOrders(customerId, page, size);
            
            return ResponseUtil.success(orders, "Orders retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving customer orders", e);
            return ResponseUtil.error("Failed to retrieve orders");
        }
    }

    @PutMapping("/orders/{orderId}/cancel")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrder(
            @PathVariable Long orderId,
            @RequestParam String reason,
            @RequestParam(required = false) String customerToken) {
        
        try {
            log.info("Cancelling order ID: {} with reason: {}", orderId, reason);
            
            OrderResponse order = orderService.cancelOrder(orderId, reason);
            
            // Send cancellation notification
            if (customerToken != null && !customerToken.isEmpty()) {
                firebaseNotificationService.sendOrderNotification(
                    order.getOrderNumber(), 
                    "CANCELLED", 
                    customerToken
                );
            }
            
            return ResponseUtil.success(order, "Order cancelled successfully");
            
        } catch (Exception e) {
            log.error("Error cancelling order ID: {}", orderId, e);
            return ResponseUtil.error("Failed to cancel order");
        }
    }

    @PostMapping("/orders/{orderId}/rate")
    public ResponseEntity<ApiResponse<String>> rateOrder(
            @PathVariable Long orderId,
            @RequestParam int rating,
            @RequestParam(required = false) String review) {
        
        try {
            log.info("Rating order ID: {} with rating: {}", orderId, rating);
            
            orderService.rateOrder(orderId, rating, review);
            
            return ResponseUtil.success("Rating submitted successfully", "Order rated successfully");
            
        } catch (Exception e) {
            log.error("Error rating order ID: {}", orderId, e);
            return ResponseUtil.error("Failed to submit rating");
        }
    }
}