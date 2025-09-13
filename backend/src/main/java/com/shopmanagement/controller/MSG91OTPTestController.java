package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.Random;

@RestController
@RequestMapping("/api/test/msg91-otp")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class MSG91OTPTestController {
    
    @Value("${msg91.auth.key:463859A66N4Ih6468c48e0dP1}")
    private String authKey;
    
    @Value("${msg91.template.otp:nammaooru}")
    private String templateId;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    /**
     * Test MSG91 OTP API directly
     */
    @PostMapping("/send/{mobile}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendOTPDirect(@PathVariable String mobile) {
        try {
            log.info("Testing MSG91 OTP API for mobile: {}", mobile);
            
            // Generate 6-digit OTP
            String otp = String.valueOf(100000 + new Random().nextInt(900000));
            
            // Format mobile number (add 91 country code if not present)
            String formattedMobile = mobile.startsWith("91") ? mobile : "91" + mobile;
            
            // Try simple SMS format with nammaooru as sender
            String url = String.format(
                "https://control.msg91.com/api/sendhttp.php?authkey=%s&mobiles=%s&message=Your%%20OTP%%20is%%20%s&sender=%s&route=4",
                authKey, formattedMobile, otp, templateId
            );
            
            log.info("Calling MSG91 API: {} (authkey hidden)", url.replace(authKey, "***"));
            
            try {
                ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
                
                log.info("MSG91 Response Status: {}", response.getStatusCode());
                log.info("MSG91 Response Body: {}", response.getBody());
                
                Map<String, Object> result = Map.of(
                    "success", response.getStatusCode() == HttpStatus.OK,
                    "message", response.getStatusCode() == HttpStatus.OK ? 
                        "OTP sent successfully" : "Failed to send OTP",
                    "status", response.getStatusCode().toString(),
                    "response", response.getBody(),
                    "testOTP", otp // For testing
                );
                
                return ResponseUtil.success(result, "MSG91 OTP API test result");
                
            } catch (Exception apiException) {
                log.error("MSG91 API call failed", apiException);
                
                Map<String, Object> result = Map.of(
                    "success", false,
                    "message", "MSG91 API call failed: " + apiException.getMessage(),
                    "testOTP", otp,
                    "error", apiException.getClass().getSimpleName()
                );
                
                return ResponseUtil.success(result, "MSG91 API test result");
            }
            
        } catch (Exception e) {
            log.error("Error in MSG91 OTP test", e);
            return ResponseUtil.error("Test failed: " + e.getMessage());
        }
    }
    
    /**
     * Test with custom template and message
     */
    @PostMapping("/send-custom")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendCustomOTP(
            @RequestParam String mobile,
            @RequestParam String templateName,
            @RequestParam String message) {
        try {
            log.info("Testing custom MSG91 message for mobile: {} with template: {}", mobile, templateName);
            
            String formattedMobile = mobile.startsWith("91") ? mobile : "91" + mobile;
            
            // URL encode the message
            String encodedMessage = java.net.URLEncoder.encode(message, "UTF-8");
            
            String url = String.format(
                "https://control.msg91.com/api/sendhttp.php?authkey=%s&mobiles=%s&message=%s&sender=%s&route=4",
                authKey, formattedMobile, encodedMessage, templateName
            );
            
            log.info("Calling MSG91 SMS API: {}", url.replace(authKey, "***"));
            
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            
            Map<String, Object> result = Map.of(
                "success", response.getStatusCode() == HttpStatus.OK,
                "message", "Custom message sent",
                "response", response.getBody(),
                "status", response.getStatusCode().toString()
            );
            
            return ResponseUtil.success(result, "Custom MSG91 test result");
            
        } catch (Exception e) {
            log.error("Error in custom MSG91 test", e);
            return ResponseUtil.error("Test failed: " + e.getMessage());
        }
    }
}