package com.shopmanagement.userservice.service;

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

    @Value("${msg91.template.otp:}")
    private String msg91OtpTemplateId;

    @Value("${msg91.template.forgot-password:}")
    private String msg91ForgotPasswordTemplateId;

    private static final String OTP_TEMPLATE = "Your OTP to complete your Namma Ooru Registration is %s. It is valid for %d minutes. - NAMMAO";
    private static final String FORGOT_PASSWORD_TEMPLATE = "Your Namma Ooru verification code is %s. It is valid for %d minutes. Do not share this with anyone. - NAMMAO";

    @Async
    public CompletableFuture<Boolean> sendOtpSms(String mobileNumber, String otp, int validityMinutes) {
        String message = String.format(OTP_TEMPLATE, otp, validityMinutes);
        return sendSms(mobileNumber, message, "OTP");
    }

    @Async
    public CompletableFuture<Boolean> sendForgotPasswordOtpSms(String mobileNumber, String otp, int validityMinutes) {
        String message = String.format(FORGOT_PASSWORD_TEMPLATE, otp, validityMinutes);
        return sendSms(mobileNumber, message, "FORGOT_PASSWORD");
    }

    private CompletableFuture<Boolean> sendSms(String mobileNumber, String message, String purpose) {
        if (!smsEnabled) {
            log.info("SMS disabled. Would send {} SMS to {}: {}", purpose, mobileNumber, message);
            return CompletableFuture.completedFuture(true);
        }

        try {
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
                    success = sendViaMsg91(formattedNumber, message, purpose);
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
            log.info("Sending SMS via Twilio to {}: {}", mobileNumber, message);
            return true;
        } catch (Exception e) {
            log.error("Error sending SMS via Twilio: {}", e.getMessage());
            return false;
        }
    }

    private boolean sendViaMsg91(String mobileNumber, String message, String purpose) {
        try {
            log.info("Sending SMS via MSG91 to {} for purpose {}: {}", mobileNumber, purpose, message);

            String formattedNumber = mobileNumber.replaceAll("\\D", "");
            if (formattedNumber.startsWith("91") && formattedNumber.length() == 12) {
                formattedNumber = formattedNumber.substring(2);
            }

            String flowId = resolveFlowId(purpose);
            if (flowId == null || flowId.isEmpty()) {
                log.error("No MSG91 flow_id configured for purpose: {}", purpose);
                return false;
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("authkey", apiKey);

            String otpCode = extractOtpFromMessage(message);
            String validityMinutes = extractValidityFromMessage(message);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("flow_id", flowId);

            Map<String, Object> recipient = new HashMap<>();
            recipient.put("mobiles", "91" + formattedNumber);

            if (otpCode != null) {
                recipient.put("var", otpCode);
            }
            if (validityMinutes != null) {
                recipient.put("var2", validityMinutes);
            }

            requestBody.put("recipients", new Object[]{recipient});

            String flowApiUrl = "https://control.msg91.com/api/v5/flow/";

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            log.info("MSG91 Flow API Request - URL: {}, Flow ID: {}, Mobile: 91{}, Purpose: {}",
                flowApiUrl, flowId, formattedNumber, purpose);

            ResponseEntity<String> response = restTemplate.postForEntity(
                flowApiUrl, request, String.class);

            log.info("MSG91 Response - Status: {}, Body: {}",
                response.getStatusCode(), response.getBody());

            return response.getStatusCode() == HttpStatus.OK;

        } catch (Exception e) {
            log.error("Error sending SMS via MSG91: {}", e.getMessage(), e);
            return false;
        }
    }

    private String resolveFlowId(String purpose) {
        if ("FORGOT_PASSWORD".equalsIgnoreCase(purpose) || "PASSWORD_RESET".equalsIgnoreCase(purpose)) {
            return msg91ForgotPasswordTemplateId;
        }
        return msg91OtpTemplateId;
    }

    private String extractValidityFromMessage(String message) {
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("valid for (\\d+) minutes");
        java.util.regex.Matcher matcher = pattern.matcher(message);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    private String extractOtpFromMessage(String message) {
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\b\\d{6}\\b");
        java.util.regex.Matcher matcher = pattern.matcher(message);
        if (matcher.find()) {
            return matcher.group();
        }
        return null;
    }

    private boolean sendViaMockService(String mobileNumber, String message, String purpose) {
        log.info("=== MOCK SMS SERVICE ===");
        log.info("To: {}", mobileNumber);
        log.info("Purpose: {}", purpose);
        log.info("Message: {}", message);
        log.info("Sender: {}", senderId);
        log.info("========================");

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        return true;
    }

    private String formatMobileNumber(String mobileNumber) {
        String digits = mobileNumber.replaceAll("\\D", "");

        if (digits.length() == 10) {
            return "91" + digits;
        }

        if (digits.length() == 12 && digits.startsWith("91")) {
            return digits;
        }

        return digits;
    }

    public boolean isSmsEnabled() {
        return smsEnabled;
    }

    public String getSmsProvider() {
        return smsProvider;
    }

    public boolean isValidIndianMobileNumber(String mobileNumber) {
        String digits = mobileNumber.replaceAll("\\D", "");

        if (digits.length() == 10) {
            return digits.matches("^[6-9][0-9]{9}$");
        }

        if (digits.length() == 12 && digits.startsWith("91")) {
            String number = digits.substring(2);
            return number.matches("^[6-9][0-9]{9}$");
        }

        return false;
    }
}
