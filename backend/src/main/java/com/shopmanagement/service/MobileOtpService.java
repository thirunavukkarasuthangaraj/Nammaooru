package com.shopmanagement.service;

import com.shopmanagement.dto.mobile.MobileOtpRequest;
import com.shopmanagement.dto.mobile.MobileOtpVerificationRequest;
import com.shopmanagement.entity.MobileOtp;
import com.shopmanagement.repository.MobileOtpRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MobileOtpService {
    
    private final MobileOtpRepository otpRepository;
    private final EmailService emailService;
    private final com.shopmanagement.repository.CustomerRepository customerRepository;
    
    @Value("${mobile.otp.expiry-minutes:10}")
    private int otpExpiryMinutes;
    
    @Value("${mobile.otp.length:6}")
    private int otpLength;
    
    @Value("${mobile.otp.max-attempts:3}")
    private int maxAttempts;
    
    @Value("${mobile.otp.rate-limit-minutes:2}")
    private int rateLimitMinutes;
    
    @Value("${mobile.otp.max-requests-per-hour:5}")
    private int maxRequestsPerHour;
    
    private final SecureRandom secureRandom = new SecureRandom();
    
    // Generate and send OTP via email
    public Map<String, Object> generateAndSendOtp(MobileOtpRequest request) {
        log.info("Generating OTP for mobile: {} and purpose: {}", request.getMobileNumber(), request.getPurpose());
        
        try {
            // Validate rate limiting
            validateRateLimit(request);
            
            // Deactivate any existing active OTPs for this mobile and purpose
            MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());
            otpRepository.deactivatePreviousOtps(request.getMobileNumber(), purpose);
            
            // Generate new OTP
            String otpCode = generateOtpCode();
            LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(otpExpiryMinutes);
            
            // Create OTP entity
            MobileOtp otp = MobileOtp.builder()
                    .mobileNumber(request.getMobileNumber())
                    .otpCode(otpCode)
                    .purpose(purpose)
                    .expiresAt(expiresAt)
                    .maxAttempts(maxAttempts)
                    .deviceId(request.getDeviceId())
                    .deviceType(request.getDeviceType())
                    .appVersion(request.getAppVersion())
                    .ipAddress(request.getIpAddress())
                    .sessionId(request.getSessionId())
                    .build();
            
            // Save OTP
            MobileOtp savedOtp = otpRepository.save(otp);
            
            // Send OTP via email (async)
            sendOtpEmail(request.getMobileNumber(), otpCode, purpose, otpExpiryMinutes);
            
            log.info("OTP generated and sent successfully for mobile: {}", request.getMobileNumber());
            
            return Map.of(
                "success", true,
                "message", "OTP sent successfully to your registered email",
                "otpId", savedOtp.getId(),
                "expiresIn", otpExpiryMinutes * 60, // seconds
                "canRetryAfter", rateLimitMinutes * 60, // seconds
                "attemptsRemaining", maxAttempts
            );
            
        } catch (Exception e) {
            log.error("Error generating OTP for mobile: {}", request.getMobileNumber(), e);
            return Map.of(
                "success", false,
                "message", e.getMessage(),
                "errorCode", "OTP_GENERATION_FAILED"
            );
        }
    }
    
    // Verify OTP
    public Map<String, Object> verifyOtp(MobileOtpVerificationRequest request) {
        log.info("Verifying OTP for mobile: {} and purpose: {}", request.getMobileNumber(), request.getPurpose());
        
        try {
            MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());
            
            // Find the OTP
            Optional<MobileOtp> otpOptional = otpRepository.findByMobileNumberAndOtpCodeAndPurposeAndIsActiveTrue(
                request.getMobileNumber(), request.getOtp(), purpose);
            
            if (otpOptional.isEmpty()) {
                log.warn("Invalid OTP provided for mobile: {}", request.getMobileNumber());
                return Map.of(
                    "success", false,
                    "message", "Invalid OTP",
                    "errorCode", "INVALID_OTP"
                );
            }
            
            MobileOtp otp = otpOptional.get();
            
            // Check if OTP is still valid
            if (!otp.canAttempt()) {
                log.warn("OTP cannot be attempted for mobile: {} - Max attempts reached or expired", request.getMobileNumber());
                return Map.of(
                    "success", false,
                    "message", "OTP has expired or maximum attempts reached",
                    "errorCode", "OTP_EXPIRED_OR_MAX_ATTEMPTS"
                );
            }
            
            // Verify device ID for security
            if (request.getDeviceId() != null && otp.getDeviceId() != null && 
                !request.getDeviceId().equals(otp.getDeviceId())) {
                log.warn("Device ID mismatch for OTP verification. Mobile: {}", request.getMobileNumber());
                otp.incrementAttempt();
                otpRepository.save(otp);
                
                return Map.of(
                    "success", false,
                    "message", "Security validation failed",
                    "errorCode", "DEVICE_MISMATCH"
                );
            }
            
            // Check if OTP is expired
            if (otp.isExpired()) {
                log.warn("Expired OTP used for mobile: {}", request.getMobileNumber());
                otp.markAsExpired();
                otpRepository.save(otp);
                
                return Map.of(
                    "success", false,
                    "message", "OTP has expired",
                    "errorCode", "OTP_EXPIRED"
                );
            }
            
            // Verify OTP code
            if (!otp.getOtpCode().equals(request.getOtp())) {
                log.warn("Wrong OTP provided for mobile: {}", request.getMobileNumber());
                otp.incrementAttempt();
                otpRepository.save(otp);
                
                int attemptsLeft = maxAttempts - otp.getAttemptCount();
                return Map.of(
                    "success", false,
                    "message", "Invalid OTP",
                    "errorCode", "WRONG_OTP",
                    "attemptsRemaining", attemptsLeft
                );
            }
            
            // OTP is valid - mark as used
            otp.markAsUsed();
            otp.setVerifiedBy(request.getDeviceId());
            otpRepository.save(otp);
            
            log.info("OTP verified successfully for mobile: {}", request.getMobileNumber());
            
            return Map.of(
                "success", true,
                "message", "OTP verified successfully",
                "verifiedAt", otp.getVerifiedAt(),
                "purpose", purpose.toString()
            );
            
        } catch (Exception e) {
            log.error("Error verifying OTP for mobile: {}", request.getMobileNumber(), e);
            return Map.of(
                "success", false,
                "message", "OTP verification failed",
                "errorCode", "VERIFICATION_ERROR"
            );
        }
    }
    
    // Resend OTP
    public Map<String, Object> resendOtp(String mobileNumber, String purpose, String deviceId) {
        log.info("Resending OTP for mobile: {} and purpose: {}", mobileNumber, purpose);
        
        try {
            // Check rate limiting
            MobileOtp.OtpPurpose otpPurpose = MobileOtp.OtpPurpose.valueOf(purpose);
            LocalDateTime fromTime = LocalDateTime.now().minusMinutes(rateLimitMinutes);
            
            Long recentOtpCount = otpRepository.countOtpsSentInTimeFrame(mobileNumber, otpPurpose, fromTime);
            if (recentOtpCount > 0) {
                return Map.of(
                    "success", false,
                    "message", "Please wait before requesting another OTP",
                    "errorCode", "RATE_LIMIT_EXCEEDED",
                    "canRetryAfter", rateLimitMinutes * 60
                );
            }
            
            // Create resend request
            MobileOtpRequest resendRequest = MobileOtpRequest.builder()
                    .mobileNumber(mobileNumber)
                    .purpose(purpose)
                    .deviceId(deviceId)
                    .build();
            
            return generateAndSendOtp(resendRequest);
            
        } catch (Exception e) {
            log.error("Error resending OTP for mobile: {}", mobileNumber, e);
            return Map.of(
                "success", false,
                "message", "Failed to resend OTP",
                "errorCode", "RESEND_FAILED"
            );
        }
    }
    
    // Validate rate limiting
    private void validateRateLimit(MobileOtpRequest request) {
        MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());
        
        // Check requests in the last few minutes
        LocalDateTime fromTime = LocalDateTime.now().minusMinutes(rateLimitMinutes);
        Long recentCount = otpRepository.countOtpsSentInTimeFrame(request.getMobileNumber(), purpose, fromTime);
        
        if (recentCount > 0) {
            throw new RuntimeException("Please wait " + rateLimitMinutes + " minutes before requesting another OTP");
        }
        
        // Check hourly limit
        LocalDateTime hourAgo = LocalDateTime.now().minusHours(1);
        Long hourlyCount = otpRepository.countOtpsSentInTimeFrame(request.getMobileNumber(), purpose, hourAgo);
        
        if (hourlyCount >= maxRequestsPerHour) {
            throw new RuntimeException("Maximum OTP requests per hour exceeded. Please try again later");
        }
        
        // Check device-based rate limiting if device ID is provided
        if (request.getDeviceId() != null) {
            LocalDateTime deviceFromTime = LocalDateTime.now().minusMinutes(rateLimitMinutes);
            Long deviceOtpCount = otpRepository.countOtpsByDeviceInTimeFrame(request.getDeviceId(), deviceFromTime);
            
            if (deviceOtpCount > 2) { // Allow max 3 OTPs per device in rate limit window
                throw new RuntimeException("Too many OTP requests from this device. Please wait");
            }
        }
    }
    
    // Generate OTP code
    private String generateOtpCode() {
        StringBuilder otp = new StringBuilder();
        for (int i = 0; i < otpLength; i++) {
            otp.append(secureRandom.nextInt(10));
        }
        return otp.toString();
    }
    
    // Send OTP via email
    @Async
    public void sendOtpEmail(String mobileNumber, String otpCode, MobileOtp.OtpPurpose purpose, int validityMinutes) {
        try {
            // For mobile registration, we need to send OTP to the email associated with the mobile number
            // Since we don't have the email in the OTP request, we'll send to a default format or look it up
            
            String subject = "Your NammaOoru Verification Code";
            String emailContent = buildOtpEmailContent(otpCode, purpose, validityMinutes);
            
            // Option 1: If we have customer's email, use it
            // For now, we'll use a placeholder - in real implementation, you'd look up the customer's email
            String recipientEmail = lookupCustomerEmail(mobileNumber);
            
            if (recipientEmail != null) {
                emailService.sendSimpleEmail(recipientEmail, subject, emailContent);
                log.info("OTP email sent to: {} for mobile: {}", recipientEmail, mobileNumber);
            } else {
                // Option 2: Send to a constructed email (mobile@domain.com)
                String constructedEmail = mobileNumber + "@nammaooru.temp"; // Temporary approach
                log.warn("No email found for mobile: {}. Would send to: {}", mobileNumber, constructedEmail);
                
                // For development, just log the OTP
                log.info("=== OTP EMAIL CONTENT ===");
                log.info("Mobile: {}", mobileNumber);
                log.info("OTP: {}", otpCode);
                log.info("Purpose: {}", purpose);
                log.info("Valid for: {} minutes", validityMinutes);
                log.info("Subject: {}", subject);
                log.info("Content: {}", emailContent);
                log.info("========================");
            }
            
        } catch (Exception e) {
            log.error("Failed to send OTP email for mobile: {}", mobileNumber, e);
        }
    }
    
    // Look up customer email by mobile number
    private String lookupCustomerEmail(String mobileNumber) {
        try {
            return customerRepository.findByMobileNumber(mobileNumber)
                    .map(customer -> customer.getEmail())
                    .orElse(null);
        } catch (Exception e) {
            log.error("Error looking up customer email for mobile: {}", mobileNumber, e);
            return null;
        }
    }
    
    // Build OTP email content
    private String buildOtpEmailContent(String otpCode, MobileOtp.OtpPurpose purpose, int validityMinutes) {
        String purposeText = getPurposeDisplayText(purpose);
        
        return String.format(
            "Dear Customer,\n\n" +
            "Your verification code for %s is:\n\n" +
            "**%s**\n\n" +
            "This code is valid for %d minutes.\n\n" +
            "If you didn't request this code, please ignore this email.\n\n" +
            "For security reasons, do not share this code with anyone.\n\n" +
            "Best regards,\n" +
            "NammaOoru Team\n\n" +
            "---\n" +
            "This is an automated message. Please do not reply to this email.",
            purposeText, otpCode, validityMinutes
        );
    }
    
    // Get display text for OTP purpose
    private String getPurposeDisplayText(MobileOtp.OtpPurpose purpose) {
        return switch (purpose) {
            case REGISTRATION -> "account registration";
            case LOGIN -> "login";
            case FORGOT_PASSWORD -> "password reset";
            case CHANGE_MOBILE -> "mobile number change";
            case VERIFY_MOBILE -> "mobile verification";
            case ORDER_CONFIRMATION -> "order confirmation";
            case ACCOUNT_VERIFICATION -> "account verification";
        };
    }
    
    // Cleanup expired OTPs (should be called by a scheduled job)
    @Transactional
    public void cleanupExpiredOtps() {
        LocalDateTime now = LocalDateTime.now();
        otpRepository.deactivateExpiredOtps(now);
        
        // Delete very old OTPs (older than 7 days)
        LocalDateTime cutoff = now.minusDays(7);
        otpRepository.deleteOldOtps(cutoff);
        
        log.info("Cleaned up expired OTPs");
    }
    
    // Get OTP statistics
    @Transactional(readOnly = true)
    public Map<String, Object> getOtpStatistics() {
        LocalDateTime dayAgo = LocalDateTime.now().minusDays(1);
        
        Long totalOtpsToday = otpRepository.countOtpsByPurposeInTimeFrame(
            MobileOtp.OtpPurpose.REGISTRATION, dayAgo);
        
        Long verifiedOtpsToday = otpRepository.countVerifiedOtpsInTimeFrame(dayAgo);
        
        return Map.of(
            "totalOtpsSentToday", totalOtpsToday,
            "verifiedOtpsToday", verifiedOtpsToday,
            "verificationRate", totalOtpsToday > 0 ? (verifiedOtpsToday * 100.0 / totalOtpsToday) : 0,
            "otpExpiryMinutes", otpExpiryMinutes,
            "maxAttemptsPerOtp", maxAttempts
        );
    }
}