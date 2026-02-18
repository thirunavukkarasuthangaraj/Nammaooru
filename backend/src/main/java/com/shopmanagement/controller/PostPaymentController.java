package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.PostPayment;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.PostPaymentService;
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
@RequestMapping("/api/post-payments")
@RequiredArgsConstructor
@Slf4j
public class PostPaymentController {

    private final PostPaymentService postPaymentService;
    private final UserRepository userRepository;

    @GetMapping("/config")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getConfig() {
        try {
            Map<String, Object> config = postPaymentService.getPaymentConfig();
            return ResponseUtil.success(config, "Payment config retrieved");
        } catch (Exception e) {
            log.error("Error getting payment config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/create-order")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createOrder(
            @RequestBody Map<String, String> request) {
        try {
            User user = getCurrentUser();
            String postType = request.get("postType");
            if (postType == null || postType.isEmpty()) {
                return ResponseUtil.badRequest("postType is required");
            }
            Map<String, Object> order = postPaymentService.createOrder(user.getId(), postType);
            return ResponseUtil.success(order, "Order created");
        } catch (Exception e) {
            log.error("Error creating payment order", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/verify")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPayment(
            @RequestBody Map<String, String> request) {
        try {
            String orderId = request.get("razorpay_order_id");
            String paymentId = request.get("razorpay_payment_id");
            String signature = request.get("razorpay_signature");

            if (orderId == null || paymentId == null || signature == null) {
                return ResponseUtil.badRequest("razorpay_order_id, razorpay_payment_id, and razorpay_signature are required");
            }

            PostPayment payment = postPaymentService.verifyPayment(orderId, paymentId, signature);

            Map<String, Object> result = Map.of(
                    "paidTokenId", payment.getId(),
                    "status", payment.getStatus().name()
            );
            return ResponseUtil.success(result, "Payment verified successfully");
        } catch (Exception e) {
            log.error("Error verifying payment", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMyPayments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            User user = getCurrentUser();
            Pageable pageable = PageRequest.of(page, size);
            Page<PostPayment> payments = postPaymentService.getMyPayments(user.getId(), pageable);
            return ResponseUtil.paginated(payments);
        } catch (Exception e) {
            log.error("Error fetching user payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllPayments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<PostPayment> payments = postPaymentService.getAllPayments(pageable);
            return ResponseUtil.paginated(payments);
        } catch (Exception e) {
            log.error("Error fetching payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/stats")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPaymentStats() {
        try {
            Map<String, Object> stats = postPaymentService.getPaymentStats();
            return ResponseUtil.success(stats, "Payment stats retrieved");
        } catch (Exception e) {
            log.error("Error fetching payment stats", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByUsername(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
