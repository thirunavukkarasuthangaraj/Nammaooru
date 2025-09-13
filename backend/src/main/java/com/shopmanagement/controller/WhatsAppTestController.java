package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.service.WhatsAppNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/test/whatsapp")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class WhatsAppTestController {
    
    private final WhatsAppNotificationService whatsAppService;
    
    /**
     * Test WhatsApp OTP sending
     */
    @PostMapping("/send-otp/{mobile}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testSendOTP(@PathVariable String mobile) {
        try {
            log.info("Testing WhatsApp OTP for mobile: {}", mobile);
            
            Map<String, Object> result = whatsAppService.sendOTP(mobile, "whatsapp");
            
            return ResponseUtil.success(result, "Test OTP result");
            
        } catch (Exception e) {
            log.error("Error testing WhatsApp OTP", e);
            return ResponseUtil.error("Test failed: " + e.getMessage());
        }
    }
    
    /**
     * Test WhatsApp OTP verification
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testVerifyOTP(
            @RequestParam String mobile, 
            @RequestParam String otp) {
        try {
            log.info("Testing OTP verification for mobile: {}", mobile);
            
            Map<String, Object> result = whatsAppService.verifyOTP(mobile, otp);
            
            return ResponseUtil.success(result, "Test OTP verification result");
            
        } catch (Exception e) {
            log.error("Error testing OTP verification", e);
            return ResponseUtil.error("Test failed: " + e.getMessage());
        }
    }
    
    /**
     * Test WhatsApp order notification
     */
    @PostMapping("/send-order-notification")
    public ResponseEntity<ApiResponse<String>> testOrderNotification(
            @RequestParam String mobile,
            @RequestParam String customerName,
            @RequestParam String orderNumber) {
        try {
            log.info("Testing order notification for mobile: {}", mobile);
            
            whatsAppService.sendOrderConfirmation(mobile, customerName, orderNumber, 250.0, "Test Shop");
            
            return ResponseUtil.success("Success", "Order notification sent");
            
        } catch (Exception e) {
            log.error("Error testing order notification", e);
            return ResponseUtil.error("Test failed: " + e.getMessage());
        }
    }
}