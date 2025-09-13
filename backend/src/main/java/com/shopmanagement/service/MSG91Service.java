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
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class MSG91Service {
    
    @Value("${msg91.auth.key:YOUR_MSG91_AUTH_KEY}")
    private String authKey;
    
    @Value("${msg91.sender.id:NAMOOR}")
    private String senderId;
    
    @Value("${msg91.template.id:YOUR_TEMPLATE_ID}")
    private String templateId;
    
    @Value("${msg91.whatsapp.enabled:true}")
    private boolean whatsappEnabled;
    
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
     * Send WhatsApp OTP to a mobile number
     */
    public Map<String, Object> sendWhatsAppOTP(String mobileNumber) {
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
                log.info("WhatsApp OTP disabled. OTP for {}: {}", mobileNumber, otp);
                response.put("success", true);
                response.put("message", "OTP sent successfully (Test mode)");
                response.put("testOTP", otp); // Only for testing
                return response;
            }
            
            // Prepare MSG91 API request
            String url = "https://control.msg91.com/api/v5/otp";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("authkey", authKey);
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("template_id", templateId);
            requestBody.put("mobile", formatMobileNumber(mobileNumber));
            requestBody.put("sender", senderId);
            requestBody.put("otp", otp);
            requestBody.put("otp_expiry", "10"); // 10 minutes
            requestBody.put("otp_length", "6");
            
            // WhatsApp specific parameters
            Map<String, Object> whatsappParams = new HashMap<>();
            whatsappParams.put("from", senderId);
            whatsappParams.put("template_name", "otp_template");
            whatsappParams.put("channel", "whatsapp");
            requestBody.put("whatsapp", whatsappParams);
            
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            
            ResponseEntity<String> apiResponse = restTemplate.exchange(
                url,
                HttpMethod.POST,
                request,
                String.class
            );
            
            if (apiResponse.getStatusCode() == HttpStatus.OK) {
                log.info("WhatsApp OTP sent successfully to {}", mobileNumber);
                response.put("success", true);
                response.put("message", "OTP sent via WhatsApp");
            } else {
                log.error("Failed to send WhatsApp OTP: {}", apiResponse.getBody());
                response.put("success", false);
                response.put("message", "Failed to send OTP");
            }
            
        } catch (Exception e) {
            log.error("Error sending WhatsApp OTP", e);
            response.put("success", false);
            response.put("message", "Error sending OTP: " + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Send SMS OTP as fallback
     */
    public Map<String, Object> sendSMSOTP(String mobileNumber) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Generate OTP if not exists
            String otp = otpStore.containsKey(mobileNumber) ? 
                otpStore.get(mobileNumber).otp : generateOTP();
            
            if (!otpStore.containsKey(mobileNumber)) {
                otpStore.put(mobileNumber, new OTPData(otp));
            }
            
            if (!whatsappEnabled) {
                log.info("SMS OTP disabled. OTP for {}: {}", mobileNumber, otp);
                response.put("success", true);
                response.put("message", "OTP sent via SMS (Test mode)");
                response.put("testOTP", otp);
                return response;
            }
            
            // MSG91 SMS API
            String url = String.format(
                "https://control.msg91.com/api/v5/otp?template_id=%s&mobile=%s&authkey=%s&otp=%s",
                templateId, formatMobileNumber(mobileNumber), authKey, otp
            );
            
            ResponseEntity<String> apiResponse = restTemplate.getForEntity(url, String.class);
            
            if (apiResponse.getStatusCode() == HttpStatus.OK) {
                response.put("success", true);
                response.put("message", "OTP sent via SMS");
            } else {
                response.put("success", false);
                response.put("message", "Failed to send SMS OTP");
            }
            
        } catch (Exception e) {
            log.error("Error sending SMS OTP", e);
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
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
                response.put("message", "Too many attempts. Please request new OTP");
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
     * Resend OTP
     */
    public Map<String, Object> resendOTP(String mobileNumber, String channel) {
        otpStore.remove(mobileNumber); // Clear old OTP
        
        if ("whatsapp".equalsIgnoreCase(channel)) {
            return sendWhatsAppOTP(mobileNumber);
        } else {
            return sendSMSOTP(mobileNumber);
        }
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
        // Add country code if not present
        if (!number.startsWith("+91") && !number.startsWith("91")) {
            return "91" + number;
        }
        return number.replace("+", "");
    }
}