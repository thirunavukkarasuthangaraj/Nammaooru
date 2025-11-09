package com.shopmanagement.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/webhooks/msg91")
@Slf4j
public class MSG91WebhookController {

    /**
     * MSG91 Delivery Report Webhook
     * This endpoint receives delivery status updates from MSG91
     */
    @PostMapping("/delivery-report")
    public ResponseEntity<Map<String, Object>> handleDeliveryReport(@RequestBody Map<String, Object> payload) {
        log.info("MSG91 Delivery Report Received: {}", payload);

        // Extract delivery information
        String mobile = (String) payload.get("mobile");
        String status = (String) payload.get("status");
        String requestId = (String) payload.get("request_id");

        log.info("SMS Delivery - Mobile: {}, Status: {}, Request ID: {}", mobile, status, requestId);

        // You can update your database here if needed
        // For example: update mobile_otps table with delivery status

        return ResponseEntity.ok(Map.of("success", true, "message", "Delivery report processed"));
    }

    /**
     * MSG91 OTP Verification Webhook (if needed)
     */
    @PostMapping("/otp-verify")
    public ResponseEntity<Map<String, Object>> handleOtpVerify(@RequestBody Map<String, Object> payload) {
        log.info("MSG91 OTP Verify Webhook: {}", payload);
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * Generic MSG91 webhook handler
     */
    @PostMapping("/callback")
    public ResponseEntity<Map<String, Object>> handleCallback(@RequestBody Map<String, Object> payload) {
        log.info("MSG91 Callback Received: {}", payload);
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * Health check for MSG91 webhook
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of("status", "healthy", "service", "MSG91 Webhook"));
    }
}
