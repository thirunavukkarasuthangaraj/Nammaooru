package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service to send daily End-of-Day (EOD) summary emails to shop owners
 * Includes: Walk-in (offline) order count, Online order count, and total amounts
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DailyOrderSummaryService {

    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final EmailService emailService;

    /**
     * Scheduled job to send daily EOD summary at 11:55 PM IST (23:55)
     * Cron: second minute hour day-of-month month day-of-week
     * 0 55 23 * * * = At 23:55:00 every day
     */
    @Scheduled(cron = "0 55 23 * * *", zone = "Asia/Kolkata")
    public void sendDailyOrderSummary() {
        log.info("🕘 Starting daily EOD order summary job at {}", LocalDateTime.now());

        try {
            // Get all approved shops
            List<Shop> approvedShops = shopRepository.findAll().stream()
                    .filter(shop -> shop.getStatus() == Shop.ShopStatus.APPROVED && shop.getIsActive())
                    .toList();
            log.info("Found {} approved shops to process", approvedShops.size());

            for (Shop shop : approvedShops) {
                try {
                    sendShopDailySummary(shop);
                } catch (Exception e) {
                    log.error("Failed to send daily summary for shop {}: {}", shop.getId(), e.getMessage());
                }
            }

            log.info("✅ Daily EOD order summary job completed");

        } catch (Exception e) {
            log.error("❌ Error in daily EOD order summary job: {}", e.getMessage(), e);
        }
    }

    /**
     * Send daily summary for a specific shop
     */
    public void sendShopDailySummary(Shop shop) {
        // Get today's date range
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(LocalTime.MAX);

        // Get today's orders for this shop
        List<Order> todayOrders = orderRepository.findByShopIdAndCreatedAtBetween(
                shop.getId(), startOfDay, endOfDay);

        if (todayOrders.isEmpty()) {
            log.info("No orders today for shop: {} ({})", shop.getName(), shop.getId());
            // Still send email with zero orders
        }

        // Calculate statistics
        DailySummaryStats stats = calculateStats(todayOrders);

        // Get shop owner email from shop entity
        String ownerEmail = shop.getOwnerEmail();
        String ownerName = shop.getOwnerName() != null ? shop.getOwnerName() : "Shop Owner";

        if (ownerEmail == null || ownerEmail.isEmpty()) {
            log.warn("No email found for shop owner of shop: {} ({})", shop.getName(), shop.getId());
            return;
        }

        // Send email
        sendSummaryEmail(ownerEmail, ownerName, shop.getName(), stats);
    }

    /**
     * Calculate daily statistics from orders
     */
    private DailySummaryStats calculateStats(List<Order> orders) {
        DailySummaryStats stats = new DailySummaryStats();

        for (Order order : orders) {
            BigDecimal amount = order.getTotalAmount() != null ? order.getTotalAmount() : BigDecimal.ZERO;

            if (order.getOrderType() == Order.OrderType.WALK_IN) {
                // Walk-in (offline/POS) order
                stats.walkInCount++;
                stats.walkInTotal = stats.walkInTotal.add(amount);
            } else {
                // Online order
                stats.onlineCount++;
                stats.onlineTotal = stats.onlineTotal.add(amount);
            }

            // Count by payment method
            if (order.getPaymentMethod() != null) {
                String paymentMethod = order.getPaymentMethod().name();
                if ("CASH_ON_DELIVERY".equals(paymentMethod) || "CASH".equals(paymentMethod)) {
                    stats.cashCount++;
                    stats.cashTotal = stats.cashTotal.add(amount);
                } else if ("UPI".equals(paymentMethod)) {
                    stats.upiCount++;
                    stats.upiTotal = stats.upiTotal.add(amount);
                } else if ("CARD".equals(paymentMethod)) {
                    stats.cardCount++;
                    stats.cardTotal = stats.cardTotal.add(amount);
                }
            }

            // Count by status
            if (order.getStatus() == Order.OrderStatus.DELIVERED ||
                order.getStatus() == Order.OrderStatus.SELF_PICKUP_COLLECTED) {
                stats.completedCount++;
            } else if (order.getStatus() == Order.OrderStatus.CANCELLED) {
                stats.cancelledCount++;
            } else {
                stats.pendingCount++;
            }
        }

        stats.totalOrders = orders.size();
        stats.grandTotal = stats.walkInTotal.add(stats.onlineTotal);

        return stats;
    }

    /**
     * Send summary email to shop owner
     */
    private void sendSummaryEmail(String email, String ownerName, String shopName, DailySummaryStats stats) {
        try {
            String today = LocalDate.now().format(DateTimeFormatter.ofPattern("dd MMM yyyy"));

            Map<String, Object> variables = new HashMap<>();
            variables.put("ownerName", ownerName);
            variables.put("shopName", shopName);
            variables.put("date", today);
            variables.put("walkInCount", stats.walkInCount);
            variables.put("walkInTotal", formatCurrency(stats.walkInTotal));
            variables.put("onlineCount", stats.onlineCount);
            variables.put("onlineTotal", formatCurrency(stats.onlineTotal));
            variables.put("totalOrders", stats.totalOrders);
            variables.put("grandTotal", formatCurrency(stats.grandTotal));
            variables.put("completedCount", stats.completedCount);
            variables.put("cancelledCount", stats.cancelledCount);
            variables.put("pendingCount", stats.pendingCount);

            // Payment method breakdown
            variables.put("cashCount", stats.cashCount);
            variables.put("cashTotal", formatCurrency(stats.cashTotal));
            variables.put("upiCount", stats.upiCount);
            variables.put("upiTotal", formatCurrency(stats.upiTotal));
            variables.put("cardCount", stats.cardCount);
            variables.put("cardTotal", formatCurrency(stats.cardTotal));

            String subject = "📊 Daily Order Summary - " + shopName + " - " + today;

            emailService.sendHtmlEmail(email, subject, "daily-order-summary", variables);
            log.info("✉️ Daily summary email sent to {} for shop: {}", email, shopName);

        } catch (Exception e) {
            log.error("Failed to send daily summary email to {}: {}", email, e.getMessage());
        }
    }

    private String formatCurrency(BigDecimal amount) {
        return "₹" + amount.setScale(0, java.math.RoundingMode.HALF_UP).toString();
    }

    /**
     * Manual trigger for testing - can be called via API
     */
    public void triggerManualSummary(Long shopId) {
        log.info("Manual daily summary triggered for shop: {}", shopId);
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found: " + shopId));
        sendShopDailySummary(shop);
    }

    /**
     * Inner class to hold daily statistics
     */
    private static class DailySummaryStats {
        int walkInCount = 0;
        BigDecimal walkInTotal = BigDecimal.ZERO;
        int onlineCount = 0;
        BigDecimal onlineTotal = BigDecimal.ZERO;
        int totalOrders = 0;
        BigDecimal grandTotal = BigDecimal.ZERO;
        int completedCount = 0;
        int cancelledCount = 0;
        int pendingCount = 0;

        // Payment method breakdown
        int cashCount = 0;
        BigDecimal cashTotal = BigDecimal.ZERO;
        int upiCount = 0;
        BigDecimal upiTotal = BigDecimal.ZERO;
        int cardCount = 0;
        BigDecimal cardTotal = BigDecimal.ZERO;
    }
}
