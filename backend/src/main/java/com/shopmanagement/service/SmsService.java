package com.shopmanagement.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
public class SmsService {
    
    private final RestTemplate restTemplate;
    
    // SMS Gateway Configuration (using TextLocal/Twilio/MSG91 as examples)
    @Value("${sms.gateway.url:https://api.textlocal.in/send/}")
    private String smsGatewayUrl;
    
    @Value("${sms.gateway.api-key:your-api-key}")
    private String apiKey;
    
    @Value("${sms.gateway.sender-id:NMROOU}")
    private String senderId;
    
    @Value("${sms.gateway.provider:TEXTLOCAL}")
    private String smsProvider;
    
    @Value("${sms.enabled:false}")
    private Boolean smsEnabled;
    
    // SMS Templates
    private static final String OTP_TEMPLATE = "Your NammaOoru verification code is: %s. Valid for %d minutes. Do not share with anyone. -NammaOoru";
    private static final String WELCOME_TEMPLATE = "Welcome to NammaOoru! Your account has been created successfully. Start shopping now! -NammaOoru";
    private static final String ORDER_CONFIRMATION_TEMPLATE = "Your order #%s has been confirmed. Amount: ₹%.2f. Track your order in the app. -NammaOoru";
    private static final String ORDER_UPDATE_TEMPLATE = "Order #%s update: %s. Check the app for details. -NammaOoru";
    private static final String DELIVERY_TEMPLATE = "Your order #%s is out for delivery. Expected time: %s. -NammaOoru";
    
    @Async
    public CompletableFuture<Boolean> sendOtpSms(String mobileNumber, String otp, int validityMinutes) {
        String message = String.format(OTP_TEMPLATE, otp, validityMinutes);
        return sendSms(mobileNumber, message, "OTP");
    }
    
    @Async
    public CompletableFuture<Boolean> sendWelcomeSms(String mobileNumber, String customerName) {
        return sendSms(mobileNumber, WELCOME_TEMPLATE, "WELCOME");
    }
    
    @Async
    public CompletableFuture<Boolean> sendOrderConfirmationSms(String mobileNumber, String orderId, Double amount) {
        String message = String.format(ORDER_CONFIRMATION_TEMPLATE, orderId, amount);
        return sendSms(mobileNumber, message, "ORDER_CONFIRMATION");
    }
    
    @Async
    public CompletableFuture<Boolean> sendOrderUpdateSms(String mobileNumber, String orderId, String status) {
        String message = String.format(ORDER_UPDATE_TEMPLATE, orderId, status);
        return sendSms(mobileNumber, message, "ORDER_UPDATE");
    }
    
    @Async
    public CompletableFuture<Boolean> sendDeliverySms(String mobileNumber, String orderId, String expectedTime) {
        String message = String.format(DELIVERY_TEMPLATE, orderId, expectedTime);
        return sendSms(mobileNumber, message, "DELIVERY");
    }
    
    @Async
    public CompletableFuture<Boolean> sendCustomSms(String mobileNumber, String message, String purpose) {
        return sendSms(mobileNumber, message, purpose);
    }
    
    private CompletableFuture<Boolean> sendSms(String mobileNumber, String message, String purpose) {
        if (!smsEnabled) {
            log.info("SMS disabled. Would send {} SMS to {}: {}", purpose, mobileNumber, message);
            return CompletableFuture.completedFuture(true);
        }
        
        try {
            // Format mobile number (ensure it's in correct format)
            String formattedNumber = formatMobileNumber(mobileNumber);
            
            boolean success = false;
            switch (smsProvider.toUpperCase()) {
                case "TEXTLOCAL":
                    success = sendViaTextLocal(formattedNumber, message);
                    break;
                case "TWILIO":
                    success = sendViaTwilio(formattedNumber, message);
                    break;
                case "MSG91":
                    success = sendViaMsg91(formattedNumber, message);
                    break;
                case "MOCK":
                default:
                    success = sendViaMockService(formattedNumber, message, purpose);
                    break;
            }
            
            if (success) {
                log.info("SMS sent successfully to {} for purpose: {}", mobileNumber, purpose);
            } else {
                log.error("Failed to send SMS to {} for purpose: {}", mobileNumber, purpose);
            }
            
            return CompletableFuture.completedFuture(success);
            
        } catch (Exception e) {
            log.error("Error sending SMS to {} for purpose {}: {}", mobileNumber, purpose, e.getMessage(), e);
            return CompletableFuture.completedFuture(false);
        }
    }
    
    private boolean sendViaTextLocal(String mobileNumber, String message) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
            Map<String, String> params = new HashMap<>();
            params.put("apikey", apiKey);
            params.put("numbers", mobileNumber);
            params.put("message", message);
            params.put("sender", senderId);
            
            String body = params.entrySet().stream()
                    .map(entry -> entry.getKey() + "=" + entry.getValue())
                    .reduce((p1, p2) -> p1 + "&" + p2)
                    .orElse("");
            
            HttpEntity<String> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(smsGatewayUrl, request, String.class);
            
            return response.getStatusCode() == HttpStatus.OK;
            
        } catch (Exception e) {
            log.error("Error sending SMS via TextLocal: {}", e.getMessage());
            return false;
        }
    }
    
    private boolean sendViaTwilio(String mobileNumber, String message) {
        try {
            // Implement Twilio SMS sending logic
            log.info("Sending SMS via Twilio to {}: {}", mobileNumber, message);
            
            // Twilio implementation would go here
            // For now, return true for demo
            return true;
            
        } catch (Exception e) {
            log.error("Error sending SMS via Twilio: {}", e.getMessage());
            return false;
        }
    }
    
    private boolean sendViaMsg91(String mobileNumber, String message) {
        try {
            // Implement MSG91 SMS sending logic
            log.info("Sending SMS via MSG91 to {}: {}", mobileNumber, message);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("authkey", apiKey);
            
            Map<String, Object> smsData = new HashMap<>();
            smsData.put("sender", senderId);
            smsData.put("route", "4");
            smsData.put("country", "91");
            
            Map<String, Object> sms = new HashMap<>();
            sms.put("message", message);
            sms.put("to", new String[]{mobileNumber});
            
            smsData.put("sms", new Map[]{sms});
            
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(smsData, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(
                "https://api.msg91.com/api/v2/sendsms", request, String.class);
            
            return response.getStatusCode() == HttpStatus.OK;
            
        } catch (Exception e) {
            log.error("Error sending SMS via MSG91: {}", e.getMessage());
            return false;
        }
    }
    
    private boolean sendViaMockService(String mobileNumber, String message, String purpose) {
        // Mock SMS service for development/testing
        log.info("=== MOCK SMS SERVICE ===");
        log.info("To: {}", mobileNumber);
        log.info("Purpose: {}", purpose);
        log.info("Message: {}", message);
        log.info("Sender: {}", senderId);
        log.info("========================");
        
        // Simulate SMS sending delay
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // For demo purposes, always return true
        return true;
    }
    
    private String formatMobileNumber(String mobileNumber) {
        // Remove all non-digits
        String digits = mobileNumber.replaceAll("\\D", "");
        
        // If it's a 10-digit number, add country code
        if (digits.length() == 10) {
            return "91" + digits;
        }
        
        // If it already has country code, return as is
        if (digits.length() == 12 && digits.startsWith("91")) {
            return digits;
        }
        
        // Return the original if we can't format it properly
        return digits;
    }
    
    public boolean isSmsEnabled() {
        return smsEnabled;
    }
    
    public String getSmsProvider() {
        return smsProvider;
    }
    
    // Bulk SMS functionality
    @Async
    public CompletableFuture<Map<String, Boolean>> sendBulkSms(Map<String, String> mobileMessages, String purpose) {
        Map<String, Boolean> results = new HashMap<>();
        
        for (Map.Entry<String, String> entry : mobileMessages.entrySet()) {
            try {
                CompletableFuture<Boolean> result = sendSms(entry.getKey(), entry.getValue(), purpose);
                results.put(entry.getKey(), result.get());
                
                // Add delay between messages to avoid rate limiting
                Thread.sleep(100);
                
            } catch (Exception e) {
                log.error("Error sending bulk SMS to {}: {}", entry.getKey(), e.getMessage());
                results.put(entry.getKey(), false);
            }
        }
        
        return CompletableFuture.completedFuture(results);
    }
    
    // SMS validation
    public boolean isValidIndianMobileNumber(String mobileNumber) {
        // Remove all non-digits
        String digits = mobileNumber.replaceAll("\\D", "");
        
        // Check if it's a valid Indian mobile number
        // Should be 10 digits starting with 6, 7, 8, or 9
        if (digits.length() == 10) {
            return digits.matches("^[6-9][0-9]{9}$");
        }
        
        // Check if it includes country code
        if (digits.length() == 12 && digits.startsWith("91")) {
            String number = digits.substring(2);
            return number.matches("^[6-9][0-9]{9}$");
        }
        
        return false;
    }
}