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

    // Same bill but with an IMAGE header — images show inline on WhatsApp (no
    // tap-to-download like PDFs), much friendlier for customers.
    // pos_bill_image uses positional variables {{1}}..{{4}} in the same order.
    @Value("${whatsapp.template.bill-receipt-image:pos_bill_image}")
    private String billReceiptImageTemplateId;

    // Marketing template for shop offers (must be approved as a MARKETING template
    // in Meta WhatsApp Manager; variables: customer_name, shop_name, offer_text)
    // Same as shop_offer but with an IMAGE header; used when the shop attaches
    // a picture to the offer (variables: customer_name, shop_name, offer_text)
    @Value("${whatsapp.template.shop-offer-image:shop_offer_image}")
    private String shopOfferImageTemplateId;

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
        return sendShopOffer(mobileNumber, customerName, shopName, offerText, null);
    }

    /**
     * Offer with an optional image attachment. When imageUrl is present the
     * shop_offer_image template (IMAGE header) is used instead of shop_offer,
     * so both templates must exist with the same body variables.
     */
    public boolean sendShopOffer(String mobileNumber, String customerName, String shopName,
                                 String offerText, String imageUrl) {
        if (!whatsappEnabled) {
            log.info("WhatsApp disabled. Would send offer to {}: {}", mobileNumber, offerText);
            return false;
        }
        boolean withImage = imageUrl != null && !imageUrl.isBlank();
        Map<String, Object> templateData = new java.util.LinkedHashMap<>();
        if (withImage) {
            templateData.put("header_image", imageUrl);
        }
        templateData.put("customer_name", customerName != null && !customerName.isBlank() ? customerName : "Customer");
        templateData.put("shop_name", shopName);
        templateData.put("offer_text", offerText);
        return sendWhatsAppMessage(mobileNumber,
                withImage ? shopOfferImageTemplateId : shopOfferTemplateId,
                templateData, "shop_offer");
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
     * Send the POS bill as an inline WhatsApp IMAGE (renders immediately in the chat,
     * no tap-to-download). Requires the bill_receipt_image template (IMAGE header,
     * body params: customer_name, shop_name, order_number, amount).
     */
    public boolean sendBillImage(String mobileNumber, String customerName, String shopName,
                                 String orderNumber, String amount, String imageUrl) {
        if (!whatsappEnabled) {
            log.info("WhatsApp disabled. Would send bill image {} to {} ({})", orderNumber, mobileNumber, imageUrl);
            return false;
        }

        Map<String, Object> templateData = new java.util.LinkedHashMap<>();
        templateData.put("header_image", imageUrl);
        templateData.put("customer_name", customerName != null && !customerName.isBlank() ? customerName : "Customer");
        templateData.put("shop_name", shopName);
        templateData.put("order_number", orderNumber);
        templateData.put("amount", amount);

        return sendWhatsAppMessage(mobileNumber, billReceiptImageTemplateId, templateData, "bill_receipt_image");
    }

    /**
     * Send a free-form (non-template) text message via the Meta Cloud API.
     * Only allowed inside the 24h customer-service window, i.e. as a REPLY to a
     * message the customer sent us — used by the inbound-order webhook to
     * acknowledge received orders. Meta provider only.
     */
    public boolean sendTextMessage(String mobileNumber, String text) {
        if (!"meta".equalsIgnoreCase(whatsappProvider)) {
            log.warn("Free-form WhatsApp text requires the meta provider; current provider is {}", whatsappProvider);
            return false;
        }
        if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                || metaAccessToken == null || metaAccessToken.isBlank()) {
            log.error("Meta WhatsApp Cloud API not configured: set whatsapp.meta.phone-number-id and whatsapp.meta.access-token");
            return false;
        }
        try {
            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "text");
            requestBody.put("text", Map.of("preview_url", false, "body", text));

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                    new HttpEntity<>(requestBody, headers), String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("WhatsApp free-form text sent to {}", mobileNumber);
                return true;
            }
            log.error("Meta Cloud API text send failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            log.error("Meta Cloud API text send failed ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("Error sending free-form WhatsApp text", e);
            return false;
        }
    }

    /**
     * Send an interactive list message (tappable product picker) via the Meta
     * Cloud API. Allowed as a reply within the 24h service window. Each row:
     * id (returned verbatim in the list_reply webhook), title (max 24 chars),
     * description (max 72 chars). Max 10 rows; extras are dropped.
     */
    public boolean sendInteractiveList(String mobileNumber, String bodyText, String buttonText,
                                       List<Map<String, String>> rows) {
        if (!"meta".equalsIgnoreCase(whatsappProvider)) {
            log.warn("Interactive WhatsApp list requires the meta provider; current provider is {}", whatsappProvider);
            return false;
        }
        if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                || metaAccessToken == null || metaAccessToken.isBlank()) {
            log.error("Meta WhatsApp Cloud API not configured: set whatsapp.meta.phone-number-id and whatsapp.meta.access-token");
            return false;
        }
        try {
            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            List<Map<String, Object>> listRows = new ArrayList<>();
            for (Map<String, String> row : rows) {
                if (listRows.size() >= 10) break;  // WhatsApp hard limit
                Map<String, Object> r = new HashMap<>();
                r.put("id", truncate(row.get("id"), 200));
                r.put("title", truncate(row.get("title"), 24));
                String description = row.get("description");
                if (description != null && !description.isBlank()) {
                    r.put("description", truncate(description, 72));
                }
                listRows.add(r);
            }

            Map<String, Object> interactive = new HashMap<>();
            interactive.put("type", "list");
            interactive.put("body", Map.of("text", truncate(bodyText, 1024)));
            interactive.put("action", Map.of(
                    "button", truncate(buttonText, 20),
                    "sections", List.of(Map.of("rows", listRows))));

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "interactive");
            requestBody.put("interactive", interactive);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                    new HttpEntity<>(requestBody, headers), String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("WhatsApp interactive list sent to {} ({} rows)", mobileNumber, listRows.size());
                return true;
            }
            log.error("Meta Cloud API interactive send failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            log.error("Meta Cloud API interactive send failed ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("Error sending WhatsApp interactive list", e);
            return false;
        }
    }

    /**
     * Send an interactive reply-buttons message (max 3 buttons) via the Meta
     * Cloud API — used by the order bot for "Confirm order / Add more".
     * buttons: id -> title (title max 20 chars). Insertion order preserved.
     */
    public boolean sendInteractiveButtons(String mobileNumber, String bodyText,
                                          Map<String, String> buttons) {
        return sendInteractiveButtons(mobileNumber, null, bodyText, buttons);
    }

    /**
     * Same as {@link #sendInteractiveButtons(String, String, Map)} but with an
     * optional image header — one self-contained card (photo + text + up to 3
     * tap targets) in a single message, no Commerce Catalogue required.
     */
    public boolean sendInteractiveButtons(String mobileNumber, String headerImageUrl, String bodyText,
                                          Map<String, String> buttons) {
        if (!"meta".equalsIgnoreCase(whatsappProvider)) {
            return false;
        }
        if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                || metaAccessToken == null || metaAccessToken.isBlank()) {
            return false;
        }
        try {
            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            List<Map<String, Object>> buttonList = new ArrayList<>();
            for (Map.Entry<String, String> b : buttons.entrySet()) {
                if (buttonList.size() >= 3) break;  // WhatsApp hard limit
                buttonList.add(Map.of(
                        "type", "reply",
                        "reply", Map.of("id", b.getKey(), "title", truncate(b.getValue(), 20))));
            }

            Map<String, Object> interactive = new HashMap<>();
            interactive.put("type", "button");
            if (headerImageUrl != null && !headerImageUrl.isBlank()) {
                interactive.put("header", Map.of("type", "image", "image", Map.of("link", headerImageUrl)));
            }
            interactive.put("body", Map.of("text", truncate(bodyText, 1024)));
            interactive.put("action", Map.of("buttons", buttonList));

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "interactive");
            requestBody.put("interactive", interactive);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                    new HttpEntity<>(requestBody, headers), String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                return true;
            }
            log.error("Meta Cloud API buttons send failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            log.error("Meta Cloud API buttons send failed ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("Error sending WhatsApp interactive buttons", e);
            return false;
        }
    }

    /**
     * Send a multi-product message from the connected Commerce Catalogue:
     * product rows show image thumbnail + name + price, and tapping opens the
     * native product page with quantity selector and Add to cart. retailerIds
     * are the catalogue retailer ids (our feed uses "sp{shopProductId}").
     */
    public boolean sendProductList(String mobileNumber, String headerText, String bodyText,
                                   String catalogIdValue, List<String> retailerIds) {
        if (!"meta".equalsIgnoreCase(whatsappProvider)) {
            return false;
        }
        if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                || metaAccessToken == null || metaAccessToken.isBlank()) {
            return false;
        }
        try {
            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            List<Map<String, Object>> items = new ArrayList<>();
            for (String retailerId : retailerIds) {
                if (items.size() >= 30) break;  // WhatsApp hard limit
                items.add(Map.of("product_retailer_id", retailerId));
            }

            Map<String, Object> interactive = new HashMap<>();
            interactive.put("type", "product_list");
            interactive.put("header", Map.of("type", "text", "text", truncate(headerText, 60)));
            interactive.put("body", Map.of("text", truncate(bodyText, 1024)));
            interactive.put("action", Map.of(
                    "catalog_id", catalogIdValue,
                    "sections", List.of(Map.of("title", "Products", "product_items", items))));

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "interactive");
            requestBody.put("interactive", interactive);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                    new HttpEntity<>(requestBody, headers), String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("WhatsApp product list ({} items) sent to {}", items.size(), mobileNumber);
                return true;
            }
            log.error("Meta Cloud API product list failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            log.error("Meta Cloud API product list failed ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("Error sending WhatsApp product list", e);
            return false;
        }
    }

    /**
     * Send a free-form image message (photo with caption) via the Meta Cloud
     * API — used by the order bot to show product photos inside the 24h
     * service window. Meta downloads the image from the public link.
     */
    public boolean sendImageMessage(String mobileNumber, String imageUrl, String caption) {
        if (!"meta".equalsIgnoreCase(whatsappProvider)) {
            return false;
        }
        if (metaPhoneNumberId == null || metaPhoneNumberId.isBlank()
                || metaAccessToken == null || metaAccessToken.isBlank()) {
            return false;
        }
        try {
            String url = String.format("https://graph.facebook.com/%s/%s/messages",
                    metaApiVersion, metaPhoneNumberId);
            if (metaAppSecret != null && !metaAppSecret.isBlank()) {
                url += "?appsecret_proof=" + computeAppSecretProof(metaAccessToken, metaAppSecret);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(metaAccessToken);

            Map<String, Object> image = new HashMap<>();
            image.put("link", imageUrl);
            if (caption != null && !caption.isBlank()) {
                image.put("caption", truncate(caption, 1024));
            }

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messaging_product", "whatsapp");
            requestBody.put("to", formatMobileNumber(mobileNumber));
            requestBody.put("type", "image");
            requestBody.put("image", image);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                    new HttpEntity<>(requestBody, headers), String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                return true;
            }
            log.error("Meta Cloud API image send failed ({}): {}", response.getStatusCode(), response.getBody());
            return false;
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            log.error("Meta Cloud API image send failed ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("Error sending WhatsApp image message", e);
            return false;
        }
    }

    private static String truncate(String value, int max) {
        if (value == null) return "";
        return value.length() <= max ? value : value.substring(0, max - 1) + "…";
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

            // First attempt sends parameter_name (required for named-variable templates
            // like bill_receipt); if Meta rejects it because the template uses numbered
            // variables ({{1}}, {{2}}...), retry once without the names — parameter order
            // already matches because callers use LinkedHashMap.
            Map<String, Object> requestBody = buildMetaTemplateRequest(
                    mobileNumber, templateName, templateData, components, true);
            log.debug("Sending WhatsApp message via Meta Cloud API: {}", requestBody);
            try {
                ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST,
                        new HttpEntity<>(requestBody, headers), String.class);
                if (response.getStatusCode().is2xxSuccessful()) {
                    log.info("WhatsApp {} sent via Meta Cloud API to {}", messageType, mobileNumber);
                    return true;
                }
                log.error("Meta Cloud API send failed ({}): {}", response.getStatusCode(), response.getBody());
                return false;
            } catch (org.springframework.web.client.HttpStatusCodeException e) {
                String errorBody = e.getResponseBodyAsString();
                if (errorBody != null && errorBody.contains("parameter_name")) {
                    log.info("Template {} uses positional variables; retrying without parameter_name", templateName);
                    Map<String, Object> retryBody = buildMetaTemplateRequest(
                            mobileNumber, templateName, templateData, components, false);
                    ResponseEntity<String> retry = restTemplate.exchange(url, HttpMethod.POST,
                            new HttpEntity<>(retryBody, headers), String.class);
                    if (retry.getStatusCode().is2xxSuccessful()) {
                        log.info("WhatsApp {} sent via Meta Cloud API to {}", messageType, mobileNumber);
                        return true;
                    }
                    log.error("Meta Cloud API retry failed ({}): {}", retry.getStatusCode(), retry.getBody());
                    return false;
                }
                log.error("Meta Cloud API send failed ({}): {}", e.getStatusCode(), errorBody);
                return false;
            }

        } catch (Exception e) {
            log.error("Error sending WhatsApp message via Meta Cloud API", e);
            return false;
        }
    }

    /**
     * Build the Cloud API template payload. headerComponents holds the already-built
     * header (image/document) component; body parameters are appended in templateData
     * iteration order, with parameter_name included only for named-variable templates.
     */
    private Map<String, Object> buildMetaTemplateRequest(String mobileNumber, String templateName,
                                                         Map<String, Object> templateData,
                                                         List<Map<String, Object>> headerComponents,
                                                         boolean includeParameterNames) {
        List<Map<String, Object>> components = new ArrayList<>(headerComponents);

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
                if (includeParameterNames) {
                    param.put("parameter_name", entry.getKey());
                }
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
        return requestBody;
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