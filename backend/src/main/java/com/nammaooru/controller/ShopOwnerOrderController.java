package com.nammaooru.controller;

import com.nammaooru.dto.*;
import com.nammaooru.entity.Order;
import com.nammaooru.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/shop-owner")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ShopOwnerOrderController {

    private final OrderService orderService;
    private final NotificationService notificationService;
    private final OTPService otpService;
    private final ProfitCalculationService profitService;
    private final DailySummaryService dailySummaryService;

    // Get shop orders
    @GetMapping("/shops/{shopId}/orders")
    public ResponseEntity<?> getShopOrders(
            @PathVariable Long shopId,
            @RequestParam(required = false) String status) {
        try {
            List<Order> orders = orderService.getShopOrders(shopId, status);
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            log.error("Error fetching shop orders: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch orders"));
        }
    }

    // Accept order
    @PostMapping("/orders/{orderId}/accept")
    public ResponseEntity<?> acceptOrder(
            @PathVariable Long orderId,
            @RequestBody OrderAcceptRequest request) {
        try {
            log.info("Accepting order {} with prep time: {}", orderId, request.getEstimatedPreparationTime());
            
            Order order = orderService.acceptOrder(orderId, request.getEstimatedPreparationTime());
            
            // Generate shop OTP
            String shopOTP = otpService.generateOTP();
            otpService.updateShopOTP(orderId, shopOTP);
            
            // Send notifications
            notificationService.sendOrderAcceptedNotifications(order, shopOTP);
            
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error accepting order: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to accept order"));
        }
    }

    // Reject order
    @PostMapping("/orders/{orderId}/reject")
    public ResponseEntity<?> rejectOrder(
            @PathVariable Long orderId,
            @RequestBody OrderRejectRequest request) {
        try {
            Order order = orderService.rejectOrder(orderId, request.getReason());
            
            // Send rejection notification
            notificationService.sendOrderRejectedNotifications(order, request.getReason());
            
            return ResponseEntity.ok(Map.of(
                "orderNumber", order.getOrderNumber(),
                "status", "REJECTED"
            ));
        } catch (Exception e) {
            log.error("Error rejecting order: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to reject order"));
        }
    }

    // Update order status
    @PutMapping("/orders/{orderId}/status")
    public ResponseEntity<?> updateOrderStatus(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> request) {
        try {
            String status = request.get("status");
            Order order = orderService.updateOrderStatus(orderId, status);
            
            // Send status notification
            notificationService.sendOrderStatusNotification(order);
            
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            log.error("Error updating order status: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to update status"));
        }
    }

    // Generate shop OTP
    @PostMapping("/orders/{orderId}/generate-otp")
    public ResponseEntity<?> generateShopOTP(@PathVariable Long orderId) {
        try {
            String otp = otpService.generateOTP();
            otpService.updateShopOTP(orderId, otp);
            
            return ResponseEntity.ok(Map.of("otp", otp));
        } catch (Exception e) {
            log.error("Error generating OTP: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to generate OTP"));
        }
    }

    // Verify shop OTP
    @PostMapping("/orders/{orderId}/verify-otp")
    public ResponseEntity<?> verifyShopOTP(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> request) {
        try {
            String otp = request.get("otp");
            boolean verified = otpService.verifyShopOTP(orderId, otp);
            
            if (verified) {
                orderService.updateOrderStatus(orderId, "PICKED_UP");
            }
            
            return ResponseEntity.ok(Map.of("verified", verified));
        } catch (Exception e) {
            log.error("Error verifying OTP: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to verify OTP"));
        }
    }

    // Get today's order stats
    @GetMapping("/shops/{shopId}/orders/stats/today")
    public ResponseEntity<?> getTodayOrderStats(@PathVariable Long shopId) {
        try {
            Map<String, Object> stats = orderService.getTodayStats(shopId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            log.error("Error fetching today's stats: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch stats"));
        }
    }

    // Get daily stats with profit
    @GetMapping("/shops/{shopId}/daily-stats")
    public ResponseEntity<?> getDailyStats(
            @PathVariable Long shopId,
            @RequestParam(required = false) String date) {
        try {
            LocalDate targetDate = date != null ? LocalDate.parse(date) : LocalDate.now();
            DailyStatsResponse stats = dailySummaryService.getDailyStats(shopId, targetDate);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            log.error("Error fetching daily stats: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch daily stats"));
        }
    }

    // Get profit analysis
    @GetMapping("/shops/{shopId}/profit-analysis")
    public ResponseEntity<?> getProfitAnalysis(
            @PathVariable Long shopId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            ProfitAnalysis analysis = profitService.calculateProfit(
                shopId,
                LocalDate.parse(startDate),
                LocalDate.parse(endDate)
            );
            return ResponseEntity.ok(analysis);
        } catch (Exception e) {
            log.error("Error calculating profit: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to calculate profit"));
        }
    }

    // Get real-time profit
    @GetMapping("/shops/{shopId}/realtime-profit")
    public ResponseEntity<?> getRealTimeProfit(@PathVariable Long shopId) {
        try {
            Map<String, Object> profit = profitService.getRealTimeProfit(shopId);
            return ResponseEntity.ok(profit);
        } catch (Exception e) {
            log.error("Error fetching real-time profit: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch profit"));
        }
    }

    // Get active orders
    @GetMapping("/shops/{shopId}/orders/active")
    public ResponseEntity<?> getActiveOrders(@PathVariable Long shopId) {
        try {
            List<Order> orders = orderService.getActiveOrders(shopId);
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            log.error("Error fetching active orders: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to fetch active orders"));
        }
    }

    // Search orders
    @GetMapping("/shops/{shopId}/orders/search")
    public ResponseEntity<?> searchOrders(
            @PathVariable Long shopId,
            @RequestParam String search) {
        try {
            List<Order> orders = orderService.searchOrders(shopId, search);
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            log.error("Error searching orders: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to search orders"));
        }
    }
}

// DTOs
@lombok.Data
class OrderAcceptRequest {
    private Long orderId;
    private String estimatedPreparationTime;
    private String notes;
}

@lombok.Data
class OrderRejectRequest {
    private Long orderId;
    private String reason;
    private Boolean suggestAlternative;
}

@lombok.Data
@lombok.Builder
class DailyStatsResponse {
    private String date;
    private Integer totalOrders;
    private Integer completedOrders;
    private Integer cancelledOrders;
    private Integer pendingOrders;
    private BigDecimal totalRevenue;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;
    private BigDecimal profitMargin;
    private BigDecimal averageOrderValue;
    private String peakHours;
    private List<TopSellingItem> topSellingItems;
    private List<OrderDetail> orderDetails;
    private CostBreakdown costBreakdown;
}

@lombok.Data
class TopSellingItem {
    private Long productId;
    private String name;
    private Integer quantity;
    private BigDecimal revenue;
    private BigDecimal profit;
}

@lombok.Data
class OrderDetail {
    private Long orderId;
    private String orderNumber;
    private String customerName;
    private String items;
    private BigDecimal total;
    private BigDecimal profit;
    private String status;
    private String time;
}

@lombok.Data
class CostBreakdown {
    private BigDecimal productCost;
    private BigDecimal deliveryFees;
    private BigDecimal platformFees;
    private BigDecimal packagingCost;
    private BigDecimal otherCosts;
}

@lombok.Data
@lombok.Builder
class ProfitAnalysis {
    private BigDecimal totalRevenue;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;
    private Integer totalOrders;
    private BigDecimal profitMargin;
    private BigDecimal averageOrderProfit;
    private Map<String, BigDecimal> profitTrend;
    private List<TopProfitableItem> topProfitableItems;
}

@lombok.Data
class TopProfitableItem {
    private String name;
    private BigDecimal profit;
    private BigDecimal margin;
}