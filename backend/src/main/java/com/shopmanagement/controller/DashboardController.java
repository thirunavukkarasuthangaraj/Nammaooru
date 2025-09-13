package com.shopmanagement.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import com.shopmanagement.repository.*;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.product.repository.MasterProductRepository;
// import com.shopmanagement.delivery.repository.DeliveryPartnerRepository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Slf4j
public class DashboardController {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final ShopRepository shopRepository;
    private final MasterProductRepository productRepository;
    // private final DeliveryPartnerRepository deliveryPartnerRepository;

    @GetMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        log.info("Fetching dashboard statistics");
        
        Map<String, Object> dashboard = new HashMap<>();
        
        // Overview Stats
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalOrders", orderRepository.count());
        stats.put("totalUsers", userRepository.count());
        stats.put("totalShops", shopRepository.count());
        stats.put("totalProducts", productRepository.count());
        stats.put("totalCustomers", customerRepository.count());
        // stats.put("totalDeliveryPartners", deliveryPartnerRepository.count());
        stats.put("totalDeliveryPartners", 0L);
        
        // Today's Stats
        LocalDateTime startOfDay = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
        LocalDateTime endOfDay = LocalDateTime.now().withHour(23).withMinute(59).withSecond(59);
        stats.put("todayOrders", orderRepository.countAnalyticsByPeriod(startOfDay, endOfDay));
        
        // Revenue Stats (simplified)
        stats.put("totalRevenue", BigDecimal.valueOf(1250000)); // Placeholder
        stats.put("todayRevenue", BigDecimal.valueOf(45000)); // Placeholder
        stats.put("monthlyRevenue", BigDecimal.valueOf(380000)); // Placeholder
        
        // Order Status Distribution
        Map<String, Long> orderStatus = new HashMap<>();
        orderStatus.put("pending", 15L);
        orderStatus.put("confirmed", 8L);
        orderStatus.put("preparing", 5L);
        orderStatus.put("delivered", 45L);
        orderStatus.put("cancelled", 3L);
        
        // Recent Activity
        Map<String, Object> recentActivity = new HashMap<>();
        recentActivity.put("newOrders", 12);
        recentActivity.put("newCustomers", 5);
        recentActivity.put("newShops", 2);
        
        dashboard.put("stats", stats);
        dashboard.put("orderStatus", orderStatus);
        dashboard.put("recentActivity", recentActivity);
        dashboard.put("timestamp", LocalDateTime.now());
        
        return ResponseEntity.ok(dashboard);
    }
    
    @GetMapping("/summary")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getDashboardSummary() {
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalOrders", orderRepository.count());
        summary.put("totalRevenue", BigDecimal.valueOf(1250000));
        summary.put("activeShops", shopRepository.count());
        summary.put("timestamp", LocalDateTime.now());
        return ResponseEntity.ok(summary);
    }
}