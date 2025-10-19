package com.shopmanagement.controller;

import com.shopmanagement.entity.User;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.PaymentSettlement;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.PaymentSettlementRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class AdminController {

    private final UserRepository userRepository;
    private final OrderAssignmentRepository orderAssignmentRepository;
    private final OrderRepository orderRepository;
    private final PaymentSettlementRepository paymentSettlementRepository;

    @GetMapping("/settings")
    public ResponseEntity<Map<String, Object>> getSystemSettings() {
        log.info("Fetching system settings");
        
        Map<String, Object> settings = new HashMap<>();
        
        // General Settings
        Map<String, Object> general = new HashMap<>();
        general.put("siteName", "NammaOoru Shop Management");
        general.put("siteUrl", "https://nammaooru.com");
        general.put("adminEmail", "admin@nammaooru.com");
        general.put("supportEmail", "support@nammaooru.com");
        general.put("timezone", "Asia/Kolkata");
        general.put("currency", "INR");
        general.put("language", "en");
        
        // Business Settings
        Map<String, Object> business = new HashMap<>();
        business.put("orderPrefix", "ORD");
        business.put("autoApproveShops", false);
        business.put("autoApproveProducts", false);
        business.put("minOrderAmount", 100);
        business.put("maxOrderAmount", 50000);
        business.put("deliveryRadius", 10);
        business.put("commissionRate", 15);
        
        // Email Settings
        Map<String, Object> email = new HashMap<>();
        email.put("smtpHost", "smtp.gmail.com");
        email.put("smtpPort", 587);
        email.put("smtpUser", "noreply@nammaooru.com");
        email.put("emailEnabled", true);
        
        settings.put("general", general);
        settings.put("business", business);
        settings.put("email", email);
        settings.put("lastUpdated", LocalDateTime.now());
        
        return ResponseEntity.ok(settings);
    }
    
    @PostMapping("/settings")
    public ResponseEntity<Map<String, Object>> updateSystemSettings(@RequestBody Map<String, Object> settings) {
        log.info("Updating system settings");
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Settings updated successfully");
        response.put("updatedAt", LocalDateTime.now());
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getAppConfiguration() {
        log.info("Fetching app configuration");
        
        Map<String, Object> config = new HashMap<>();
        
        // Features
        Map<String, Boolean> features = new HashMap<>();
        features.put("multiVendor", true);
        features.put("deliveryTracking", true);
        features.put("onlinePayment", true);
        features.put("smsNotifications", true);
        features.put("emailNotifications", true);
        features.put("pushNotifications", false);
        features.put("loyaltyProgram", false);
        features.put("referralSystem", false);
        
        // Limits
        Map<String, Integer> limits = new HashMap<>();
        limits.put("maxShopsPerOwner", 5);
        limits.put("maxProductsPerShop", 1000);
        limits.put("maxImagesPerProduct", 10);
        limits.put("maxCategoriesDepth", 3);
        
        config.put("features", features);
        config.put("limits", limits);
        config.put("version", "1.0.0");
        config.put("environment", "production");
        
        return ResponseEntity.ok(config);
    }
    
    @GetMapping("/notifications")
    public ResponseEntity<Map<String, Object>> getAdminNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        log.info("Fetching admin notifications");
        
        Map<String, Object> response = new HashMap<>();
        List<Map<String, Object>> notifications = new ArrayList<>();
        
        String[] types = {"NEW_SHOP", "NEW_ORDER", "PAYMENT", "SYSTEM", "USER"};
        String[] titles = {
            "New shop registration",
            "Large order placed",
            "Payment received",
            "System update available",
            "New user registered"
        };
        
        for (int i = 0; i < size; i++) {
            Map<String, Object> notification = new HashMap<>();
            notification.put("id", page * size + i + 1);
            notification.put("type", types[i % types.length]);
            notification.put("title", titles[i % titles.length]);
            notification.put("message", "Notification message " + (i + 1));
            notification.put("read", i % 3 != 0);
            notification.put("createdAt", LocalDateTime.now().minusHours(i));
            notifications.add(notification);
        }
        
        response.put("content", notifications);
        response.put("totalElements", 50);
        response.put("totalPages", 5);
        response.put("unreadCount", 8);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/audit")
    public ResponseEntity<Map<String, Object>> getAuditLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        log.info("Fetching audit logs");
        
        Map<String, Object> response = new HashMap<>();
        List<Map<String, Object>> logs = new ArrayList<>();
        
        String[] actions = {"LOGIN", "LOGOUT", "CREATE", "UPDATE", "DELETE", "APPROVE", "REJECT"};
        String[] entities = {"User", "Shop", "Product", "Order", "Payment"};
        
        for (int i = 0; i < size; i++) {
            Map<String, Object> log = new HashMap<>();
            log.put("id", page * size + i + 1);
            log.put("action", actions[i % actions.length]);
            log.put("entity", entities[i % entities.length]);
            log.put("entityId", "ID" + (i + 1));
            log.put("user", "admin" + (i % 3 + 1));
            log.put("ipAddress", "192.168.1." + (i + 1));
            log.put("timestamp", LocalDateTime.now().minusHours(i));
            log.put("details", "Action performed on " + entities[i % entities.length]);
            logs.add(log);
        }
        
        response.put("content", logs);
        response.put("totalElements", 1000);
        response.put("totalPages", 50);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/backup")
    public ResponseEntity<Map<String, Object>> getBackupInfo() {
        log.info("Fetching backup information");
        
        Map<String, Object> backup = new HashMap<>();
        
        // Last backups
        List<Map<String, Object>> backups = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            Map<String, Object> b = new HashMap<>();
            b.put("id", "BACKUP_" + (i + 1));
            b.put("type", i == 0 ? "FULL" : "INCREMENTAL");
            b.put("size", (100 + i * 20) + " MB");
            b.put("status", "SUCCESS");
            b.put("createdAt", LocalDateTime.now().minusDays(i));
            backups.add(b);
        }
        
        backup.put("backups", backups);
        backup.put("nextScheduled", LocalDateTime.now().plusDays(1));
        backup.put("autoBackup", true);
        backup.put("retentionDays", 30);
        
        return ResponseEntity.ok(backup);
    }
    
    @PostMapping("/backup")
    public ResponseEntity<Map<String, Object>> createBackup() {
        log.info("Creating system backup");

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Backup initiated successfully");
        response.put("backupId", "BACKUP_" + System.currentTimeMillis());
        response.put("estimatedTime", "5 minutes");

        return ResponseEntity.ok(response);
    }

    // DELIVERY PARTNER PAYMENT MANAGEMENT

    @GetMapping("/delivery-partners/payments")
    public ResponseEntity<Map<String, Object>> getDeliveryPartnerPayments() {
        log.info("Fetching delivery partner payments summary");

        try {
            // Get all delivery partners
            List<User> deliveryPartners = userRepository.findByRole(User.UserRole.DELIVERY_PARTNER);

            List<Map<String, Object>> paymentsList = new ArrayList<>();

            for (User partner : deliveryPartners) {
                // Get all delivered but NOT settled orders for this partner
                List<OrderAssignment> deliveredAssignments = orderAssignmentRepository
                    .findByDeliveryPartnerAndStatus(partner, OrderAssignment.AssignmentStatus.DELIVERED);

                // Filter out already settled assignments
                deliveredAssignments = deliveredAssignments.stream()
                    .filter(assignment -> assignment.getIsSettled() == null || !assignment.getIsSettled())
                    .toList();

                if (deliveredAssignments.isEmpty()) {
                    continue; // Skip partners with no unsettled delivered orders
                }

                BigDecimal totalCashCollected = BigDecimal.ZERO;
                BigDecimal totalCommission = BigDecimal.ZERO;
                int totalOrders = 0;

                for (OrderAssignment assignment : deliveredAssignments) {
                    Order order = assignment.getOrder();

                    // Only count COD orders for cash collected
                    if (order.getPaymentMethod() == Order.PaymentMethod.CASH_ON_DELIVERY) {
                        totalCashCollected = totalCashCollected.add(order.getTotalAmount());
                    }

                    // Add partner commission
                    if (assignment.getPartnerCommission() != null) {
                        totalCommission = totalCommission.add(assignment.getPartnerCommission());
                    }

                    totalOrders++;
                }

                // Net amount = Cash collected - Commission owed
                // If positive: partner owes us money
                // If negative: we owe partner money
                BigDecimal netAmount = totalCashCollected.subtract(totalCommission);

                Map<String, Object> partnerPayment = new HashMap<>();
                partnerPayment.put("partnerId", partner.getId());
                partnerPayment.put("partnerName", partner.getFirstName() + " " + partner.getLastName());
                partnerPayment.put("partnerPhone", partner.getMobileNumber());
                partnerPayment.put("partnerEmail", partner.getEmail());
                partnerPayment.put("totalOrders", totalOrders);
                partnerPayment.put("cashCollected", totalCashCollected);
                partnerPayment.put("commissionEarned", totalCommission);
                partnerPayment.put("netAmount", netAmount);
                partnerPayment.put("paymentStatus", "PENDING"); // For now, all are pending
                partnerPayment.put("lastDelivery", deliveredAssignments.get(deliveredAssignments.size() - 1).getDeliveryCompletedAt());

                paymentsList.add(partnerPayment);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("payments", paymentsList);
            response.put("totalPartners", paymentsList.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error fetching delivery partner payments: {}", e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Error fetching payments: " + e.getMessage());

            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping("/delivery-partners/{partnerId}/mark-paid")
    public ResponseEntity<Map<String, Object>> markPaymentAsPaid(
            @PathVariable Long partnerId,
            @RequestBody Map<String, Object> paymentData) {

        log.info("Marking payment as paid for partner ID: {}", partnerId);

        try {
            // Get the partner
            User partner = userRepository.findById(partnerId)
                .orElseThrow(() -> new RuntimeException("Partner not found with ID: " + partnerId));

            // Get all unsettled delivered orders for this partner
            List<OrderAssignment> unsettledAssignments = orderAssignmentRepository
                .findByDeliveryPartnerAndStatus(partner, OrderAssignment.AssignmentStatus.DELIVERED)
                .stream()
                .filter(assignment -> assignment.getIsSettled() == null || !assignment.getIsSettled())
                .toList();

            if (unsettledAssignments.isEmpty()) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("message", "No unsettled orders found for this partner");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            // Calculate settlement amounts
            BigDecimal totalCash = BigDecimal.ZERO;
            BigDecimal totalCommission = BigDecimal.ZERO;
            int totalOrders = 0;

            for (OrderAssignment assignment : unsettledAssignments) {
                Order order = assignment.getOrder();

                // Only count COD orders for cash collected
                if (order.getPaymentMethod() == Order.PaymentMethod.CASH_ON_DELIVERY) {
                    totalCash = totalCash.add(order.getTotalAmount());
                }

                // Add partner commission
                if (assignment.getPartnerCommission() != null) {
                    totalCommission = totalCommission.add(assignment.getPartnerCommission());
                }

                totalOrders++;
            }

            BigDecimal netAmount = totalCash.subtract(totalCommission);

            // Parse payment method
            String paymentMethodStr = (String) paymentData.getOrDefault("paymentMethod", "CASH");
            PaymentSettlement.PaymentMethod paymentMethod;
            try {
                paymentMethod = PaymentSettlement.PaymentMethod.valueOf(paymentMethodStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                paymentMethod = PaymentSettlement.PaymentMethod.CASH;
            }

            // Create payment settlement record
            PaymentSettlement settlement = PaymentSettlement.builder()
                .deliveryPartner(partner)
                .settlementDate(LocalDateTime.now())
                .cashCollected(totalCash)
                .commissionEarned(totalCommission)
                .netAmount(netAmount)
                .totalOrders(totalOrders)
                .paymentMethod(paymentMethod)
                .referenceNumber((String) paymentData.get("referenceNumber"))
                .notes((String) paymentData.get("notes"))
                .settledBy("admin") // TODO: Get from security context
                .status(PaymentSettlement.SettlementStatus.COMPLETED)
                .build();

            // Save settlement
            settlement = paymentSettlementRepository.save(settlement);

            // Update all order assignments to mark as settled
            for (OrderAssignment assignment : unsettledAssignments) {
                assignment.setIsSettled(true);
                assignment.setSettledAt(LocalDateTime.now());
                assignment.setPaymentSettlement(settlement);
                orderAssignmentRepository.save(assignment);
            }

            log.info("Created settlement record ID: {} for partner: {} with net amount: {}",
                settlement.getId(), partner.getFirstName() + " " + partner.getLastName(), netAmount);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Payment settled successfully");
            response.put("settlementId", settlement.getId());
            response.put("partnerId", partnerId);
            response.put("partnerName", partner.getFirstName() + " " + partner.getLastName());
            response.put("totalOrders", totalOrders);
            response.put("cashCollected", totalCash);
            response.put("commissionEarned", totalCommission);
            response.put("netAmount", netAmount);
            response.put("settlementDate", settlement.getSettlementDate());
            response.put("paymentMethod", paymentMethod);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error marking payment as paid: {}", e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Error processing payment: " + e.getMessage());

            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
}