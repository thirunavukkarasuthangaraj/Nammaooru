package com.shopmanagement.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/finance")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class FinanceController {

    @GetMapping("/revenue")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getRevenueOverview() {
        log.info("Fetching revenue overview");
        
        Map<String, Object> revenue = new HashMap<>();
        revenue.put("totalRevenue", BigDecimal.valueOf(2500000));
        revenue.put("monthlyRevenue", BigDecimal.valueOf(450000));
        revenue.put("weeklyRevenue", BigDecimal.valueOf(125000));
        revenue.put("dailyRevenue", BigDecimal.valueOf(35000));
        revenue.put("yearToDate", BigDecimal.valueOf(1850000));
        
        // Monthly trend
        List<Map<String, Object>> monthlyTrend = new ArrayList<>();
        String[] months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun"};
        for (String month : months) {
            Map<String, Object> data = new HashMap<>();
            data.put("month", month);
            data.put("revenue", BigDecimal.valueOf(350000 + Math.random() * 150000));
            monthlyTrend.add(data);
        }
        revenue.put("monthlyTrend", monthlyTrend);
        
        // Revenue by category
        Map<String, BigDecimal> byCategory = new HashMap<>();
        byCategory.put("Electronics", BigDecimal.valueOf(850000));
        byCategory.put("Clothing", BigDecimal.valueOf(620000));
        byCategory.put("Food", BigDecimal.valueOf(530000));
        byCategory.put("Others", BigDecimal.valueOf(500000));
        revenue.put("byCategory", byCategory);
        
        revenue.put("timestamp", LocalDateTime.now());
        return ResponseEntity.ok(revenue);
    }
    
    @GetMapping("/payouts")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getPartnerPayouts() {
        log.info("Fetching partner payouts");
        
        Map<String, Object> payouts = new HashMap<>();
        
        // Pending payouts
        List<Map<String, Object>> pendingPayouts = new ArrayList<>();
        for (int i = 1; i <= 5; i++) {
            Map<String, Object> payout = new HashMap<>();
            payout.put("partnerId", "SHOP" + i);
            payout.put("partnerName", "Shop " + i);
            payout.put("amount", BigDecimal.valueOf(15000 + i * 5000));
            payout.put("dueDate", LocalDateTime.now().plusDays(i));
            payout.put("status", "PENDING");
            pendingPayouts.add(payout);
        }
        
        payouts.put("pendingPayouts", pendingPayouts);
        payouts.put("totalPending", BigDecimal.valueOf(125000));
        payouts.put("totalPaid", BigDecimal.valueOf(890000));
        payouts.put("nextPayoutDate", LocalDateTime.now().plusDays(3));
        
        return ResponseEntity.ok(payouts);
    }
    
    @GetMapping("/commission")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getCommissionSettings() {
        log.info("Fetching commission settings");
        
        Map<String, Object> commission = new HashMap<>();
        
        // Commission rates
        Map<String, Object> rates = new HashMap<>();
        rates.put("standard", 15.0);
        rates.put("premium", 12.0);
        rates.put("newShop", 10.0);
        rates.put("delivery", 20.0);
        
        commission.put("rates", rates);
        commission.put("totalCollected", BigDecimal.valueOf(375000));
        commission.put("monthlyAverage", BigDecimal.valueOf(62500));
        
        return ResponseEntity.ok(commission);
    }
    
    @PostMapping("/commission")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> updateCommissionSettings(@RequestBody Map<String, Object> settings) {
        log.info("Updating commission settings: {}", settings);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Commission settings updated successfully");
        response.put("updatedAt", LocalDateTime.now());
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/reports")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getFinancialReports() {
        log.info("Fetching financial reports");
        
        Map<String, Object> reports = new HashMap<>();
        
        // Available reports
        List<Map<String, Object>> availableReports = new ArrayList<>();
        String[] reportTypes = {"Monthly Revenue", "Quarterly Summary", "Annual Report", "Tax Report", "Partner Payouts"};
        
        for (String type : reportTypes) {
            Map<String, Object> report = new HashMap<>();
            report.put("name", type);
            report.put("lastGenerated", LocalDateTime.now().minusDays((int)(Math.random() * 30)));
            report.put("status", "AVAILABLE");
            availableReports.add(report);
        }
        
        reports.put("availableReports", availableReports);
        reports.put("lastUpdated", LocalDateTime.now());
        
        return ResponseEntity.ok(reports);
    }
    
    @GetMapping("/transactions")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getTransactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        log.info("Fetching transactions - page: {}, size: {}", page, size);
        
        Map<String, Object> response = new HashMap<>();
        List<Map<String, Object>> transactions = new ArrayList<>();
        
        for (int i = 1; i <= size; i++) {
            Map<String, Object> transaction = new HashMap<>();
            transaction.put("id", "TXN" + (page * size + i));
            transaction.put("type", i % 2 == 0 ? "CREDIT" : "DEBIT");
            transaction.put("amount", BigDecimal.valueOf(1000 + Math.random() * 10000));
            transaction.put("description", "Transaction " + i);
            transaction.put("date", LocalDateTime.now().minusDays(i));
            transaction.put("status", "COMPLETED");
            transactions.add(transaction);
        }
        
        response.put("content", transactions);
        response.put("totalElements", 100);
        response.put("totalPages", 10);
        response.put("number", page);
        response.put("size", size);
        
        return ResponseEntity.ok(response);
    }
}