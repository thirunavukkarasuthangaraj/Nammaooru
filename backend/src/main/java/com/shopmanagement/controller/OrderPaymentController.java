package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderPayment;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.OrderPaymentService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.io.BufferedReader;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class OrderPaymentController {

    private final OrderPaymentService orderPaymentService;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    @PostMapping("/customer/orders/{orderId}/payment/create-order")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createOrder(
            @PathVariable Long orderId, Authentication authentication) {
        try {
            requireOwnedOrder(orderId, authentication);
            Map<String, Object> result = orderPaymentService.createOrder(orderId);
            return ResponseUtil.success(result, "Payment order created");
        } catch (Exception e) {
            log.error("Error creating order payment for order {}", orderId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/customer/orders/{orderId}/payment/verify")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPayment(
            @PathVariable Long orderId, Authentication authentication,
            @RequestBody Map<String, String> request) {
        try {
            requireOwnedOrder(orderId, authentication);
            String razorpayOrderId = request.get("razorpay_order_id");
            String paymentId = request.get("razorpay_payment_id");
            String signature = request.get("razorpay_signature");
            if (razorpayOrderId == null || paymentId == null) {
                return ResponseUtil.badRequest("razorpay_order_id and razorpay_payment_id are required");
            }
            OrderPayment payment = orderPaymentService.verifyPayment(razorpayOrderId, paymentId, signature);
            return ResponseUtil.success(Map.of("status", payment.getStatus().name()), "Payment verified");
        } catch (Exception e) {
            log.error("Error verifying order payment for order {}", orderId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Razorpay calls this directly (no user session) — the webhook signature itself,
     * verified inside handleWebhook against the configured secret, is the auth here.
     */
    @PostMapping("/order-payments/webhook")
    public ResponseEntity<String> webhook(HttpServletRequest request,
                                           @RequestHeader(value = "X-Razorpay-Signature", required = false) String signature) {
        try {
            StringBuilder body = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    body.append(line);
                }
            }
            orderPaymentService.handleWebhook(body.toString(), signature);
            return ResponseEntity.ok("OK");
        } catch (Exception e) {
            log.error("Error handling Razorpay webhook", e);
            // Still 200 — Razorpay retries on non-2xx, and a body/parsing error won't fix
            // itself on retry. We've logged it for manual follow-up instead.
            return ResponseEntity.ok("ERROR");
        }
    }

    @GetMapping("/order-payments/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getConfig() {
        try {
            return ResponseUtil.success(Map.of("gatewayFeePercent", orderPaymentService.getGatewayFeePercent()), "Config retrieved");
        } catch (Exception e) {
            log.error("Error getting order payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/order-payments/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> updateConfig(@RequestBody Map<String, String> body) {
        try {
            if (body.get("gatewayFeePercent") != null) {
                orderPaymentService.setGatewayFeePercent(new java.math.BigDecimal(body.get("gatewayFeePercent")));
            }
            return ResponseUtil.success(null, "Config updated");
        } catch (Exception e) {
            log.error("Error updating order payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/order-payments/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<OrderPayment> payments = orderPaymentService.listAll(pageable);
            return ResponseUtil.paginated(payments);
        } catch (Exception e) {
            log.error("Error listing order payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private void requireOwnedOrder(Long orderId, Authentication authentication) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (isAdmin) return;

        boolean owns = order.getCustomer() != null && (
                (order.getCustomer().getMobileNumber() != null && order.getCustomer().getMobileNumber().equals(user.getMobileNumber()))
                || (order.getCustomer().getEmail() != null && order.getCustomer().getEmail().equalsIgnoreCase(user.getEmail())));
        if (!owns) {
            throw new RuntimeException("This order does not belong to you");
        }
    }
}
