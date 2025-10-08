package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.entity.Order;
import com.shopmanagement.service.OrderService;
import com.shopmanagement.service.OrderAssignmentService;
import com.shopmanagement.service.DeliveryConfirmationService;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
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
import java.util.Optional;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Slf4j
public class OrderController {

    private final OrderService orderService;
    private final OrderAssignmentService assignmentService;
    private final DeliveryConfirmationService deliveryConfirmationService;
    private final OrderRepository orderRepository;
    private final OrderAssignmentRepository orderAssignmentRepository;
    
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

        // Auto-assignment is handled in OrderService.updateOrderStatus()

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

        // Auto-assignment is handled in OrderService.updateOrderStatus()

        return ResponseUtil.success(response, "Order marked as ready successfully");
    }
    
    @PostMapping("/{orderId}/prepare")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderResponse>> startPreparingOrder(@PathVariable Long orderId) {
        log.info("Starting preparation for order: {}", orderId);
        OrderResponse response = orderService.updateOrderStatus(orderId, Order.OrderStatus.PREPARING);
        return ResponseUtil.success(response, "Order preparation started successfully");
    }

    @PostMapping("/{orderId}/generate-pickup-otp")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> generatePickupOTP(@PathVariable Long orderId) {
        log.info("Generating pickup OTP for order: {}", orderId);
        try {
            String otp = deliveryConfirmationService.generatePickupOTP(orderId);

            Map<String, Object> response = Map.of(
                "otp", otp,
                "orderId", orderId,
                "message", "Pickup OTP generated successfully. Please share this with delivery partner."
            );

            return ResponseUtil.success(response, "Pickup OTP generated successfully");
        } catch (Exception e) {
            log.error("Error generating pickup OTP for order {}: {}", orderId, e.getMessage());
            return ResponseUtil.error("Failed to generate pickup OTP: " + e.getMessage());
        }
    }

    @PostMapping("/{orderId}/verify-pickup-otp")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPickupOTP(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> request) {
        log.info("Shop owner verifying pickup OTP for order: {}", orderId);

        String enteredOtp = request.get("otp");
        if (enteredOtp == null || enteredOtp.trim().isEmpty()) {
            return ResponseUtil.error("OTP is required");
        }

        try {
            // Get the order entity
            Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

            // Verify OTP matches
            if (order.getPickupOtp() == null || !order.getPickupOtp().equals(enteredOtp.trim())) {
                log.warn("Invalid OTP entered for order {}: expected={}, entered={}",
                    orderId, order.getPickupOtp(), enteredOtp);
                return ResponseUtil.error("Invalid OTP. Please check with the delivery partner.");
            }

            // OTP is valid - set verified timestamp
            order.setPickupOtpVerifiedAt(java.time.LocalDateTime.now());

            // Check delivery type - SELF_PICKUP goes directly to DELIVERED
            String finalStatus;
            String successMessage;

            if (order.getDeliveryType() == Order.DeliveryType.SELF_PICKUP) {
                // Self-pickup: customer collects from shop, mark as DELIVERED immediately
                order.setStatus(Order.OrderStatus.DELIVERED);
                order.setActualDeliveryTime(java.time.LocalDateTime.now());

                // Mark payment as PAID if it's Cash on Delivery
                if (order.getPaymentMethod() == Order.PaymentMethod.CASH_ON_DELIVERY) {
                    order.setPaymentStatus(Order.PaymentStatus.PAID);
                    log.info("✅ Payment marked as PAID for self-pickup order {}", orderId);
                }

                finalStatus = "DELIVERED";
                successMessage = "Order handed over to customer successfully";
                log.info("✅ Self-pickup order {} marked as DELIVERED", orderId);
            } else {
                // Home delivery: hand over to delivery partner, mark as OUT_FOR_DELIVERY
                order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);

                // Update the OrderAssignment status to PICKED_UP so delivery partner can see it
                Optional<OrderAssignment> assignmentOpt = orderAssignmentRepository.findByOrderIdAndStatus(
                    orderId, OrderAssignment.AssignmentStatus.ACCEPTED);

                if (assignmentOpt.isPresent()) {
                    OrderAssignment assignment = assignmentOpt.get();
                    assignment.setStatus(OrderAssignment.AssignmentStatus.PICKED_UP);
                    orderAssignmentRepository.save(assignment);
                    log.info("✅ OrderAssignment status updated to PICKED_UP for order {}", orderId);
                }

                finalStatus = "OUT_FOR_DELIVERY";
                successMessage = "Order handed over to delivery partner successfully";
                log.info("✅ Home delivery order {} marked as OUT_FOR_DELIVERY", orderId);
            }

            orderRepository.save(order);

            Map<String, Object> responseData = Map.of(
                "orderId", orderId,
                "message", successMessage,
                "newStatus", finalStatus
            );

            return ResponseUtil.success(responseData, "Pickup verified successfully");
        } catch (Exception e) {
            log.error("Error verifying pickup OTP for order {}: {}", orderId, e.getMessage(), e);
            return ResponseUtil.error("Failed to verify pickup OTP: " + e.getMessage());
        }
    }

    @PostMapping("/{orderId}/mark-payment-collected")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> markPaymentCollected(@PathVariable Long orderId) {
        log.info("Marking payment as collected for order: {}", orderId);

        try {
            // Get the order
            Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

            // Check if payment method is COD
            if (order.getPaymentMethod() != Order.PaymentMethod.CASH_ON_DELIVERY) {
                return ResponseUtil.error("Payment collection is only for Cash on Delivery orders");
            }

            // Check if order is delivered
            if (order.getStatus() != Order.OrderStatus.DELIVERED) {
                return ResponseUtil.error("Order must be delivered before marking payment as collected");
            }

            // Mark payment as PAID
            order.setPaymentStatus(Order.PaymentStatus.PAID);
            orderRepository.save(order);

            log.info("✅ Payment marked as collected for order {}", orderId);

            Map<String, Object> responseData = Map.of(
                "orderId", orderId,
                "paymentStatus", "PAID",
                "message", "Payment collected successfully"
            );

            return ResponseUtil.success(responseData, "Payment marked as collected successfully");
        } catch (Exception e) {
            log.error("Error marking payment as collected for order {}: {}", orderId, e.getMessage(), e);
            return ResponseUtil.error("Failed to mark payment as collected: " + e.getMessage());
        }
    }

    @PostMapping("/{orderId}/handover-self-pickup")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> handoverSelfPickup(@PathVariable Long orderId) {
        log.info("Handing over self-pickup order: {}", orderId);

        try {
            // Get the order
            Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

            // Verify it's a self-pickup order
            if (order.getDeliveryType() != Order.DeliveryType.SELF_PICKUP) {
                return ResponseUtil.error("Order is not a self-pickup order");
            }

            // Check if order is ready for pickup
            if (order.getStatus() != Order.OrderStatus.READY_FOR_PICKUP) {
                return ResponseUtil.error("Order must be ready for pickup before handover. Current status: " + order.getStatus());
            }

            // Mark order as collected
            order.setStatus(Order.OrderStatus.SELF_PICKUP_COLLECTED);
            order.setActualDeliveryTime(java.time.LocalDateTime.now());

            // Mark payment as paid (for COD orders)
            if (order.getPaymentMethod() == Order.PaymentMethod.CASH_ON_DELIVERY) {
                order.setPaymentStatus(Order.PaymentStatus.PAID);
            }

            orderRepository.save(order);

            log.info("✅ Self-pickup order handed over successfully for order {}", orderId);

            Map<String, Object> responseData = Map.of(
                "orderId", orderId,
                "orderNumber", order.getOrderNumber(),
                "status", "SELF_PICKUP_COLLECTED",
                "paymentStatus", order.getPaymentStatus().name(),
                "message", "Order handed over successfully"
            );

            return ResponseUtil.success(responseData, "Order handed over successfully");
        } catch (Exception e) {
            log.error("Error handing over self-pickup order {}: {}", orderId, e.getMessage(), e);
            return ResponseUtil.error("Failed to handover order: " + e.getMessage());
        }
    }
}