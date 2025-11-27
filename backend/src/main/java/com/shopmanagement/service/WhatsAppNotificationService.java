package com.shopmanagement.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * WhatsApp Notification Service using MSG91
 * Handles both OTP and Order notifications via WhatsApp
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WhatsAppNotificationService {
    
    @Value("${msg91.auth.key:YOUR_MSG91_AUTH_KEY}")
    private String authKey;
    
    @Value("${msg91.sender.id:NAMOOR}")
    private String senderId;

    @Value("${msg91.whatsapp.integrated-number:15558914648}")
    private String integratedNumber;
    
    @Value("${msg91.whatsapp.enabled:false}")
    private boolean whatsappEnabled;
    
    @Value("${msg91.api.base-url:https://control.msg91.com/api/v5}")
    private String apiBaseUrl;
    
    // Template IDs for different message types
    @Value("${msg91.template.otp:YOUR_OTP_TEMPLATE_ID}")
    private String otpTemplateId;
    
    @Value("${msg91.template.order-confirmation:YOUR_ORDER_CONFIRMATION_TEMPLATE_ID}")
    private String orderConfirmationTemplateId;
    
    @Value("${msg91.template.order-status:YOUR_ORDER_STATUS_TEMPLATE_ID}")
    private String orderStatusTemplateId;
    
    @Value("${msg91.template.order-delivered:YOUR_ORDER_DELIVERED_TEMPLATE_ID}")
    private String orderDeliveredTemplateId;
    
    @Value("${msg91.whatsapp.namespace:020b365c_912b_4032_b27e_c343ddbc1e08}")
    private String whatsappNamespace;
    
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    // Store OTPs temporarily (in production, use Redis)
    private final Map<String, OTPData> otpStore = new ConcurrentHashMap<>();
    
    private static class OTPData {
        String otp;
        long timestamp;
        int attempts;
        
        OTPData(String otp) {
            this.otp = otp;
            this.timestamp = System.currentTimeMillis();
            this.attempts = 0;
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() - timestamp > TimeUnit.MINUTES.toMillis(10);
        }
    }
    
    /**
     * Send OTP via WhatsApp
     */
    public Map<String, Object> sendOTP(String mobileNumber, String channel) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Validate mobile number
            if (!isValidMobileNumber(mobileNumber)) {
                response.put("success", false);
                response.put("message", "Invalid mobile number format");
                return response;
            }
            
            // Generate 6-digit OTP
            String otp = generateOTP();
            
            // Store OTP for verification
            otpStore.put(mobileNumber, new OTPData(otp));
            
            if (!whatsappEnabled) {
                log.info("WhatsApp disabled (Test mode). OTP for {}: {}", mobileNumber, otp);
                response.put("success", true);
                response.put("message", "OTP sent successfully (Test mode)");
                response.put("testOTP", otp); // Only for testing
                return response;
            }
            
            // Prepare MSG91 WhatsApp API request
            Map<String, Object> templateData = new HashMap<>();
            templateData.put("otp", otp);
            templateData.put("expiry", "10");
            templateData.put("company", "NammaOoru");
            
            boolean sent = sendWhatsAppMessage(mobileNumber, otpTemplateId, templateData, "otp");
            
            if (sent) {
                response.put("success", true);
                response.put("message", "OTP sent via WhatsApp");
            } else if ("sms".equalsIgnoreCase(channel)) {
                // Fallback to SMS
                return sendSMSOTP(mobileNumber, otp);
            } else {
                response.put("success", false);
                response.put("message", "Failed to send OTP");
            }
            
        } catch (Exception e) {
            log.error("Error sending WhatsApp OTP", e);
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Send SMS OTP as fallback
     */
    private Map<String, Object> sendSMSOTP(String mobileNumber, String otp) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            String url = String.format(
                "%s/otp?template_id=%s&mobile=%s&authkey=%s&otp=%s",
                apiBaseUrl, otpTemplateId, formatMobileNumber(mobileNumber), authKey, otp
            );
            
            ResponseEntity<String> apiResponse = restTemplate.getForEntity(url, String.class);
            
            if (apiResponse.getStatusCode() == HttpStatus.OK) {
                response.put("success", true);
                response.put("message", "OTP sent via SMS");
            } else {
                response.put("success", false);
                response.put("message", "Failed to send SMS");
            }
        } catch (Exception e) {
            log.error("Error sending SMS OTP", e);
            response.put("success", false);
            response.put("message", "SMS Error: " + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Verify OTP
     */
    public Map<String, Object> verifyOTP(String mobileNumber, String otp) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            OTPData otpData = otpStore.get(mobileNumber);
            
            if (otpData == null) {
                response.put("success", false);
                response.put("message", "OTP not found or expired");
                return response;
            }
            
            if (otpData.isExpired()) {
                otpStore.remove(mobileNumber);
                response.put("success", false);
                response.put("message", "OTP expired");
                return response;
            }
            
            if (otpData.attempts >= 3) {
                otpStore.remove(mobileNumber);
                response.put("success", false);
                response.put("message", "Too many attempts");
                return response;
            }
            
            if (otpData.otp.equals(otp)) {
                otpStore.remove(mobileNumber);
                response.put("success", true);
                response.put("message", "OTP verified successfully");
            } else {
                otpData.attempts++;
                response.put("success", false);
                response.put("message", "Invalid OTP");
                response.put("attemptsLeft", 3 - otpData.attempts);
            }
            
        } catch (Exception e) {
            log.error("Error verifying OTP", e);
            response.put("success", false);
            response.put("message", "Verification error");
        }
        
        return response;
    }
    
    /**
     * Send Order Confirmation via WhatsApp
     */
    public void sendOrderConfirmation(String mobileNumber, String customerName, 
                                     String orderNumber, Double orderAmount, String shopName) {
        try {
            if (!whatsappEnabled) {
                log.info("WhatsApp disabled. Would send order confirmation to {}", mobileNumber);
                return;
            }
            
            Map<String, Object> templateData = new HashMap<>();
            templateData.put("customer_name", customerName);
            templateData.put("order_number", orderNumber);
            templateData.put("order_amount", String.format("₹%.2f", orderAmount));
            templateData.put("shop_name", shopName);
            templateData.put("company", "NammaOoru");
            
            sendWhatsAppMessage(mobileNumber, orderConfirmationTemplateId, templateData, "order_confirmation");
            
        } catch (Exception e) {
            log.error("Failed to send order confirmation via WhatsApp", e);
        }
    }
    
    /**
     * Send Order Status Update via WhatsApp
     */
    public void sendOrderStatusUpdate(String mobileNumber, String customerName, 
                                     String orderNumber, String status, String message) {
        try {
            if (!whatsappEnabled) {
                log.info("WhatsApp disabled. Would send status update to {}", mobileNumber);
                return;
            }
            
            Map<String, Object> templateData = new HashMap<>();
            templateData.put("customer_name", customerName);
            templateData.put("order_number", orderNumber);
            templateData.put("status", status);
            templateData.put("message", message);
            templateData.put("company", "NammaOoru");
            
            // Use different template based on status
            String templateId = status.equals("DELIVERED") ? 
                orderDeliveredTemplateId : orderStatusTemplateId;
            
            sendWhatsAppMessage(mobileNumber, templateId, templateData, "order_status");
            
        } catch (Exception e) {
            log.error("Failed to send order status update via WhatsApp", e);
        }
    }
    
    /**
     * Send Order Ready for Pickup notification
     */
    public void sendOrderReadyNotification(String mobileNumber, String customerName, 
                                          String orderNumber, String shopName) {
        try {
            if (!whatsappEnabled) {
                log.info("WhatsApp disabled. Would send ready notification to {}", mobileNumber);
                return;
            }
            
            Map<String, Object> templateData = new HashMap<>();
            templateData.put("customer_name", customerName);
            templateData.put("order_number", orderNumber);
            templateData.put("shop_name", shopName);
            templateData.put("pickup_time", "30 minutes");
            templateData.put("company", "NammaOoru");
            
            sendWhatsAppMessage(mobileNumber, orderStatusTemplateId, templateData, "order_ready");
            
        } catch (Exception e) {
            log.error("Failed to send order ready notification via WhatsApp", e);
        }
    }
    
    /**
     * Send marketing message via WhatsApp
     */
    public boolean sendMarketingMessage(String mobileNumber, String templateName, Map<String, Object> templateData) {
        return sendWhatsAppMessage(mobileNumber, templateName, templateData, "marketing");
    }

    /**
     * Generic WhatsApp message sender using MSG91 API v5
     */
    private boolean sendWhatsAppMessage(String mobileNumber, String templateId,
                                       Map<String, Object> templateData, String messageType) {
        try {
            // MSG91 WhatsApp API endpoint (correct URL)
            String url = "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("authkey", authKey);
            
            // Build components object based on template data (MSG91 format)
            Map<String, Object> components = new HashMap<>();

            // Add header if present (for templates with images/videos)
            if (templateData != null && templateData.containsKey("header_image")) {
                Map<String, Object> headerParam = new HashMap<>();
                headerParam.put("type", "image");

                // Create nested image object with link (MSG91 format)
                Map<String, Object> imageObject = new HashMap<>();
                imageObject.put("link", String.valueOf(templateData.get("header_image")));
                headerParam.put("image", imageObject);

                components.put("header_1", headerParam);
            }

            // Add body parameters if data exists
            if (templateData != null && !templateData.isEmpty()) {
                int paramIndex = 1;
                for (Map.Entry<String, Object> entry : templateData.entrySet()) {
                    // Skip header_image as it's already processed
                    if ("header_image".equals(entry.getKey())) {
                        continue;
                    }
                    Map<String, Object> bodyParam = new HashMap<>();
                    bodyParam.put("type", "text");
                    bodyParam.put("text", String.valueOf(entry.getValue())); // Changed from "value" to "text"
                    components.put("body_" + paramIndex, bodyParam);
                    paramIndex++;
                }
            }

            // Build to_and_components array
            List<Map<String, Object>> toAndComponents = new ArrayList<>();
            Map<String, Object> toComponent = new HashMap<>();
            toComponent.put("to", List.of(formatMobileNumber(mobileNumber)));
            toComponent.put("components", components);
            toAndComponents.add(toComponent);
            
            // Build template object
            Map<String, Object> template = new HashMap<>();
            template.put("name", templateId); // Use template name directly
            
            Map<String, Object> language = new HashMap<>();
            language.put("code", "en");
            language.put("policy", "deterministic");
            template.put("language", language);
            
            template.put("namespace", whatsappNamespace); // Your namespace from config
            template.put("to_and_components", toAndComponents);
            
            // Build payload
            Map<String, Object> payload = new HashMap<>();
            payload.put("messaging_product", "whatsapp");
            payload.put("type", "template");
            payload.put("template", template);
            
            // Build request body
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("integrated_number", integratedNumber); // WhatsApp number from config
            requestBody.put("content_type", "template");
            requestBody.put("payload", payload);
            
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            
            log.debug("Sending WhatsApp message request: {}", requestBody);
            
            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.POST,
                request,
                String.class
            );
            
            if (response.getStatusCode() == HttpStatus.OK || response.getStatusCode() == HttpStatus.CREATED) {
                log.info("WhatsApp {} sent successfully to {}", messageType, mobileNumber);
                return true;
            } else {
                log.error("Failed to send WhatsApp message: {}", response.getBody());
                return false;
            }
            
        } catch (Exception e) {
            log.error("Error sending WhatsApp message", e);
            return false;
        }
    }
    
    /**
     * Resend OTP
     */
    public Map<String, Object> resendOTP(String mobileNumber, String channel) {
        otpStore.remove(mobileNumber); // Clear old OTP
        return sendOTP(mobileNumber, channel);
    }
    
    private String generateOTP() {
        Random random = new Random();
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }
    
    private boolean isValidMobileNumber(String number) {
        // Indian mobile number validation
        return number != null && number.matches("^[6-9]\\d{9}$");
    }
    
    private String formatMobileNumber(String number) {
        // Remove any spaces or special characters
        number = number.replaceAll("[^0-9]", "");

        // Add country code if not present (expecting 10 digit Indian number)
        if (number.length() == 10) {
            return "91" + number;
        }

        // If already has country code, ensure it's without + prefix
        if (number.startsWith("91") && number.length() == 12) {
            return number;
        }

        // Return as-is if already formatted
        return number;
    }
}