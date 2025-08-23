package com.nammaooru.controller;

import com.nammaooru.dto.*;
import com.nammaooru.entity.Order;
import com.nammaooru.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OrderFlowController {

    private final OrderService orderService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final DeliveryService deliveryService;
    private final OTPService otpService;

    // Place new order
    @PostMapping("/place")
    public ResponseEntity<?> placeOrder(@Valid @RequestBody OrderRequest orderRequest) {
        try {
            log.info("Placing order for customer: {}", orderRequest.getCustomerId());
            
            // Create order
            Order order = orderService.createOrder(orderRequest);
            
            // Generate OTPs
            String shopOTP = otpService.generateOTP();
            String customerOTP = otpService.generateOTP();
            otpService.storeOrderOTPs(order.getId(), shopOTP, customerOTP);
            
            // Send notifications
            notificationService.sendOrderPlacedNotifications(order, customerOTP);
            
            // Send confirmation email
            emailService.sendOrderConfirmation(
                order.getCustomerEmail(),
                order.getOrderNumber(),
                order.getCustomerName(),
                customerOTP
            );
            
            OrderResponse response = OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .status(order.getStatus())
                .totalAmount(order.getTotalAmount())
                .estimatedDeliveryTime("30-45 minutes")
                .createdAt(order.getCreatedAt())
                .build();
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error placing order: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to place order: " + e.getMessage()));
        }
    }

    // Get order by ID
    @GetMapping("/{id}")
    public ResponseEntity<?> getOrderById(@PathVariable Long id) {
        try {
            Order order = orderService.getOrderById(id);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error fetching order: ", e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Order not found"));
        }
    }

    // Get order by number
    @GetMapping("/number/{orderNumber}")
    public ResponseEntity<?> getOrderByNumber(@PathVariable String orderNumber) {
        try {
            Order order = orderService.getOrderByNumber(orderNumber);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error fetching order by number: ", e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Order not found"));
        }
    }

    // Update order status
    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateOrderStatus(
            @PathVariable Long id,
            @RequestParam String status) {
        try {
            Order order = orderService.updateOrderStatus(id, status);
            
            // Send status notification
            notificationService.sendOrderStatusNotification(order);
            
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error updating order status: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to update status"));
        }
    }

    // Cancel order
    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelOrder(
            @PathVariable Long id,
            @RequestParam String reason) {
        try {
            Order order = orderService.cancelOrder(id, reason);
            
            // Send cancellation notification
            notificationService.sendOrderCancellationNotification(order, reason);
            
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error cancelling order: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to cancel order"));
        }
    }

    // Get delivery info for order
    @GetMapping("/{id}/delivery-info")
    public ResponseEntity<?> getOrderDeliveryInfo(@PathVariable Long id) {
        try {
            Map<String, Object> deliveryInfo = deliveryService.getDeliveryInfo(id);
            return ResponseEntity.ok(deliveryInfo);
        } catch (Exception e) {
            log.error("Error fetching delivery info: ", e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Delivery info not found"));
        }
    }
}

// DTOs
@lombok.Data
@lombok.Builder
class OrderRequest {
    private Long customerId;
    private Long shopId;
    private List<OrderItem> items;
    private DeliveryAddress deliveryAddress;
    private String paymentMethod;
    private String paymentStatus;
    private String notes;
    private BigDecimal subtotal;
    private BigDecimal taxAmount;
    private BigDecimal deliveryFee;
    private BigDecimal discountAmount;
    private BigDecimal totalAmount;
}

@lombok.Data
class OrderItem {
    private Long shopProductId;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;
    private String specialInstructions;
}

@lombok.Data
class DeliveryAddress {
    private String contactName;
    private String phone;
    private String address;
    private String city;
    private String state;
    private String postalCode;
    private String landmark;
}

@lombok.Data
@lombok.Builder
class OrderResponse {
    private Long id;
    private String orderNumber;
    private String status;
    private String paymentStatus;
    private BigDecimal totalAmount;
    private String estimatedDeliveryTime;
    private LocalDateTime createdAt;
}