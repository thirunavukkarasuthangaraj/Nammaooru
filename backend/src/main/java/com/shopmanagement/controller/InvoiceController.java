package com.shopmanagement.controller;

import com.shopmanagement.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/invoices")
@RequiredArgsConstructor
@Slf4j
public class InvoiceController {
    
    private final InvoiceService invoiceService;
    
    @GetMapping("/order/{orderId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Map<String, Object>> getOrderInvoice(@PathVariable Long orderId) {
        log.info("Generating invoice for order: {}", orderId);
        try {
            Map<String, Object> invoiceData = invoiceService.generateInvoiceData(orderId);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Invoice generated successfully",
                "data", invoiceData
            ));
        } catch (Exception e) {
            log.error("Error generating invoice for order: {}", orderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "Failed to generate invoice: " + e.getMessage()
                ));
        }
    }
    
    @PostMapping("/order/{orderId}/send")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> sendInvoiceEmail(@PathVariable Long orderId) {
        log.info("Sending invoice email for order: {}", orderId);
        try {
            invoiceService.sendInvoiceEmail(orderId);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Invoice email sent successfully"
            ));
        } catch (Exception e) {
            log.error("Error sending invoice email for order: {}", orderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "Failed to send invoice email: " + e.getMessage()
                ));
        }
    }
    
    @GetMapping("/reports/monthly")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getMonthlyInvoiceReport(
            @RequestParam int year,
            @RequestParam int month) {
        log.info("Generating monthly invoice report for {}-{}", year, month);
        try {
            List<Map<String, Object>> report = invoiceService.generateMonthlyInvoiceReport(year, month);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Monthly report generated successfully",
                "data", report
            ));
        } catch (Exception e) {
            log.error("Error generating monthly report for {}-{}", year, month, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "Failed to generate monthly report: " + e.getMessage()
                ));
        }
    }
    
    @GetMapping("/reports/platform-earnings")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getPlatformEarningsReport(
            @RequestParam int year,
            @RequestParam int month) {
        log.info("Generating platform earnings report for {}-{}", year, month);
        try {
            Map<String, Object> report = invoiceService.generatePlatformEarningsReport(year, month);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Platform earnings report generated successfully",
                "data", report
            ));
        } catch (Exception e) {
            log.error("Error generating platform earnings report for {}-{}", year, month, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "Failed to generate platform earnings report: " + e.getMessage()
                ));
        }
    }
    
    @PostMapping("/order/{orderId}/auto-send")
    @PreAuthorize("hasRole('SYSTEM')")
    public ResponseEntity<Map<String, Object>> autoSendInvoiceOnDelivery(@PathVariable Long orderId) {
        log.info("Auto-sending invoice for delivered order: {}", orderId);
        try {
            // This endpoint is called automatically when order status changes to DELIVERED
            invoiceService.sendInvoiceEmail(orderId);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Invoice automatically sent on delivery"
            ));
        } catch (Exception e) {
            log.error("Error auto-sending invoice for order: {}", orderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "Failed to auto-send invoice: " + e.getMessage()
                ));
        }
    }
}