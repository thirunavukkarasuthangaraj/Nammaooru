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

    @Value("${msg91.template.bill-receipt:bill_receipt}")
    private String billReceiptTemplateId;

    // Marketing template for shop offers (must be approved as a MARKETING template
    // in Meta WhatsApp Manager; variables: customer_name, shop_name, offer_text)
    @Value("${whatsapp.template.shop-offer:shop_offer}")
    private String shopOfferTemplateId;
    
    @Value("${msg91.whatsapp.namespace:020b365c_912b_4032_b27e_c343ddbc1e08}")
    private String whatsappNamespace;

    // Provider switch: "msg91" (default) or "meta" (direct WhatsApp Cloud API).
    // MSG91 config stays in place so it can be re-enabled by flipping this back.
    @Value("${whatsapp.provider:msg91}")
    private String whatsappProvider;

    @Value("${whatsapp.meta.phone-number-id:}")
    private String metaPhoneNumberId;

    @Value("${whatsapp.meta.access-token:}")
    private String metaAccessToken;

    @Value("${whatsapp.meta.api-version:v21.0}")
    private String metaApiVersion;

    @Value("${whatsapp.meta.template-language:en}")
    private String metaTemplateLanguage;

    // Optional: when set, appsecret_proof is attached to every Graph API call so a
    // leaked access token is useless without the app secret (enable together with
    // "Require app secret proof" + server IP allow list in the Meta app settings).
    @Value("${whatsapp.meta.app-secret:}")
    private String metaAppSecret;
    
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
     * Send a shop offer to a customer using the approved marketing template.
     * Template body variables, in order: customer_name, shop_name, offer_text.
     */
    public boolean sendShopOffer(String mobileNumber, String customerName, String shopName, String offerText) {
        if (!whatsappEnabled) {
            log.info("WhatsApp disabled. Would send offer to {}: {}", mobileNumber, offerText);
            return false;
        }
        Map<String, Object> templateData = new java.util.LinkedHashMap<>();
        templateData.put("customer_name", customerName != null && !customerName.isBlank() ? customerName : "Customer");
        templateData.put("shop_name", shopName);
        templateData.put("offer_text", offerText);
        return sendWhatsAppMessage(mobileNumber, shopOfferTemplateId, templateData, "shop_offer");
    }

    /**
     * Send the POS bill as a WhatsApp document (PDF).
     * Requires an MSG91-approved WhatsApp template with a document header
     * (configured via msg91.template.bill-receipt) whose body params match
     * the order below: customer_name, shop_name, order_number, amount.
     */
    public boolean sendBillDocument(String mobileNumber, String customerName, String shopName,
                                     String orderNumber, String amount, String pdfUrl, String pdfFileName) {
        if (!whatsappEnabled) {
            log.info("WhatsApp disabled. Would send bill {} to {} ({})", orderNumber, mobileNumber, pdfUrl);
            return false;
        }

        // LinkedHashMap: sendWhatsAppMessage assigns body_1, body_2... in iteration order,
        // so insertion order here must match the MSG91 template's variable order exactly.
        Map<String, Object> templateData = new java.util.LinkedHashMap<>();
        templateData.put("header_document", pdfUrl);
        templateData.put("header_document_filename", pdfFileName);
        templateData.put("customer_name", customerName != null && !customerName.isBlank() ? customerName : "Customer");
        templateData.put("shop_name", shopName);
        templateData.put("order_number", orderNumber);
        templateData.put("amount", amount);

        return sendWhatsAppMessage(mobileNumber, billReceiptTemplateId, templateData, "bill_receipt");
    }

    /**
     * Generic WhatsApp template sender. Routes to the configured provider:
     * MSG91 (default) or Meta WhatsApp Cloud API (whatsapp.provider=meta).
     */
    private boolean sendWhatsAppMessage(String mobileNumber, String templateId,
                                       Map<String, Object> templateData, String messageType) {
        if ("meta".equalsIgnoreCase(whatsappProvider)) {
            return sendViaMetaCloudApi(mobileNumber, templateId, templateData, messageType);
        }
        return sendViaMsg91(mobileNumber, templateId, templateData, messageType);
    }

    /**
     * Send a template message directly via Meta's WhatsApp Cloud API
     * (graph.facebook.com), bypassing MSG91. Templates must be approved in
     * Meta WhatsApp Manager under the connected WABA.
     */
    private boolean sendViaMetaCloudApi(String mobileNumber, String templateName,
                                        Map<String, Object> templateData, String messageType) {
        try {
            if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                    || metaAccessToken == null || metaAccessToken.isBlank()) {
                log.error("Meta WhatsApp Cloud API not configured: set whatsapp.meta.phone-number-id and whatsapp.meta.access-token");
                return false;
            }

            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            List<Map<String, Object>> components = new ArrayList<>();

            // Header component (image or document), same templateData keys as the MSG91 path
            if (templateData != null && templateData.containsKey("header_image")) {
                Map<String, Object> image = new HashMap<>();
                image.put("link", String.valueOf(templateData.get("header_image")));
                Map<String, Object> param = new HashMap<>();
                param.put("type", "image");
                param.put("image", image);
                components.add(Map.of("type", "header", "parameters", List.of(param)));
            } else if (templateData != null && templateData.containsKey("header_document")) {
                Map<String, Object> document = new HashMap<>();
                document.put("link", String.valueOf(templateData.get("header_document")));
                Object fileName = templateData.get("header_document_filename");
                if (fileName != null) {
                    document.put("filename", String.valueOf(fileName));
                }
                Map<String, Object> param = new HashMap<>();
                param.put("type", "document");
                param.put("document", document);
                components.add(Map.of("type", "header", "parameters", List.of(param)));
            }

            // Body parameters in templateData iteration order (callers use LinkedHashMap
            // when order matters). Templates in the production WABA use named variables
            // ({{customer_name}}...), so each parameter carries parameter_name = the map key,
            // which callers keep identical to the template's variable names.
            if (templateData != null && !templateData.isEmpty()) {
                List<Map<String, Object>> bodyParams = new ArrayList<>();
                for (Map.Entry<String, Object> entry : templateData.entrySet()) {
                    if ("header_image".equals(entry.getKey())
                            || "header_document".equals(entry.getKey())
                            || "header_document_filename".equals(entry.getKey())) {
                        continue;
                    }
                    Map<String, Object> param = new HashMap<>();
                    param.put("type", "text");
                    param.put("parameter_name", entry.getKey());
                    param.put("text", String.valueOf(entry.getValue()));
                    bodyParams.add(param);
                }
                if (!bodyParams.isEmpty()) {
                    components.add(Map.of("type", "body", "parameters", bodyParams));
                }
            }

            Map<String, Object> template = new HashMap<>();
            template.put("name", templateName);
            template.put("language", Map.of("code", metaTemplateLanguage));
            template.put("components", components);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "template");
            requestBody.put("template", template);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            log.debug("Sending WhatsApp message via Meta Cloud API: {}", requestBody);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("WhatsApp {} sent via Meta Cloud API to {}", messageType, mobileNumber);
                return true;
            }
            log.error("Meta Cloud API send failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;

        } catch (Exception e) {
            log.error("Error sending WhatsApp message via Meta Cloud API", e);
            return false;
        }
    }

    /**
     * Generic WhatsApp message sender using MSG91 API v5
     */
    private boolean sendViaMsg91(String mobileNumber, String templateId,
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

            // Add header if present (for templates with a document/PDF attachment)
            if (templateData != null && templateData.containsKey("header_document")) {
                Map<String, Object> headerParam = new HashMap<>();
                headerParam.put("type", "document");

                Map<String, Object> documentObject = new HashMap<>();
                documentObject.put("link", String.valueOf(templateData.get("header_document")));
                Object fileName = templateData.get("header_document_filename");
                if (fileName != null) {
                    documentObject.put("filename", String.valueOf(fileName));
                }
                headerParam.put("document", documentObject);

                components.put("header_1", headerParam);
            }

            // Add body parameters if data exists
            if (templateData != null && !templateData.isEmpty()) {
                int paramIndex = 1;
                for (Map.Entry<String, Object> entry : templateData.entrySet()) {
                    // Skip header fields as they're already processed above
                    if ("header_image".equals(entry.getKey())
                            || "header_document".equals(entry.getKey())
                            || "header_document_filename".equals(entry.getKey())) {
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
    
    /** HMAC-SHA256 of the access token keyed with the app secret (Meta appsecret_proof). */
    private String computeAppSecretProof(String accessToken, String appSecret) {
        try {
            javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
            mac.init(new javax.crypto.spec.SecretKeySpec(appSecret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(accessToken.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException("Failed to compute appsecret_proof", e);
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