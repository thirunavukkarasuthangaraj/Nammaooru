package com.shopmanagement.userservice.service;

import com.shopmanagement.userservice.dto.mobile.MobileOtpRequest;
import com.shopmanagement.userservice.dto.mobile.MobileOtpVerificationRequest;
import com.shopmanagement.userservice.entity.MobileOtp;
import com.shopmanagement.userservice.repository.MobileOtpRepository;
import com.shopmanagement.userservice.repository.UserRepository;
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
    private final SmsService smsService;
    private final UserRepository userRepository;

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

    public Map<String, Object> generateAndSendOtp(MobileOtpRequest request) {
        log.info("Generating OTP for mobile: {} and purpose: {}", request.getMobileNumber(), request.getPurpose());

        try {
            validateRateLimit(request);

            MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());
            otpRepository.deactivatePreviousOtps(request.getMobileNumber(), purpose);

            String otpCode = generateOtpCode();
            LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(otpExpiryMinutes);

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

            MobileOtp savedOtp = otpRepository.save(otp);

            smsService.sendOtpSms(request.getMobileNumber(), otpCode, otpExpiryMinutes);

            log.info("OTP generated and sent successfully via SMS for mobile: {}", request.getMobileNumber());

            return Map.of(
                "success", true,
                "message", "OTP sent successfully to " + request.getMobileNumber(),
                "otpId", savedOtp.getId(),
                "expiresIn", otpExpiryMinutes * 60,
                "canRetryAfter", rateLimitMinutes * 60,
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

    public Map<String, Object> verifyOtp(MobileOtpVerificationRequest request) {
        log.info("Verifying OTP for mobile: {} and purpose: {}", request.getMobileNumber(), request.getPurpose());

        try {
            MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());

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

            if (!otp.canAttempt()) {
                log.warn("OTP cannot be attempted for mobile: {} - Max attempts reached or expired", request.getMobileNumber());
                return Map.of(
                    "success", false,
                    "message", "OTP has expired or maximum attempts reached",
                    "errorCode", "OTP_EXPIRED_OR_MAX_ATTEMPTS"
                );
            }

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

    public Map<String, Object> resendOtp(String mobileNumber, String purpose, String deviceId) {
        log.info("Resending OTP for mobile: {} and purpose: {}", mobileNumber, purpose);

        try {
            MobileOtp.OtpPurpose otpPurpose = MobileOtp.OtpPurpose.valueOf(purpose);

            Optional<MobileOtp> validOtp = otpRepository.findValidOtp(mobileNumber, otpPurpose, LocalDateTime.now());

            boolean canUseExistingOtp = false;
            if (validOtp.isPresent()) {
                MobileOtp otp = validOtp.get();
                if (otp.canAttempt()) {
                    canUseExistingOtp = true;
                }
            }

            if (canUseExistingOtp) {
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
            }

            otpRepository.deactivatePreviousOtps(mobileNumber, otpPurpose);

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

    private void validateRateLimit(MobileOtpRequest request) {
        MobileOtp.OtpPurpose purpose = MobileOtp.OtpPurpose.valueOf(request.getPurpose());

        Optional<MobileOtp> validOtp = otpRepository.findValidOtp(request.getMobileNumber(), purpose, LocalDateTime.now());

        boolean canUseExistingOtp = false;
        if (validOtp.isPresent()) {
            MobileOtp otp = validOtp.get();
            if (otp.canAttempt()) {
                canUseExistingOtp = true;
            }
        }

        if (canUseExistingOtp) {
            LocalDateTime fromTime = LocalDateTime.now().minusMinutes(rateLimitMinutes);
            Long recentCount = otpRepository.countOtpsSentInTimeFrame(request.getMobileNumber(), purpose, fromTime);

            if (recentCount > 0) {
                throw new RuntimeException("Please wait " + rateLimitMinutes + " minutes before requesting another OTP");
            }
        }

        LocalDateTime hourAgo = LocalDateTime.now().minusHours(1);
        Long hourlyCount = otpRepository.countOtpsSentInTimeFrame(request.getMobileNumber(), purpose, hourAgo);

        if (hourlyCount >= maxRequestsPerHour) {
            throw new RuntimeException("Maximum OTP requests per hour exceeded. Please try again later");
        }

        if (request.getDeviceId() != null) {
            LocalDateTime deviceFromTime = LocalDateTime.now().minusMinutes(rateLimitMinutes);
            Long deviceOtpCount = otpRepository.countOtpsByDeviceInTimeFrame(request.getDeviceId(), deviceFromTime);

            if (deviceOtpCount > 2) {
                throw new RuntimeException("Too many OTP requests from this device. Please wait");
            }
        }
    }

    private String generateOtpCode() {
        StringBuilder otp = new StringBuilder();
        for (int i = 0; i < otpLength; i++) {
            otp.append(secureRandom.nextInt(10));
        }
        return otp.toString();
    }

    @Async
    public void sendOtpEmail(String mobileNumber, String otpCode, MobileOtp.OtpPurpose purpose, int validityMinutes) {
        try {
            String subject = "Your NammaOoru Verification Code";
            String emailContent = buildOtpEmailContent(otpCode, purpose, validityMinutes);

            // Look up user email by mobile number (replaces CustomerRepository dependency)
            String recipientEmail = lookupUserEmail(mobileNumber);

            if (recipientEmail != null) {
                emailService.sendSimpleEmail(recipientEmail, subject, emailContent);
                log.info("OTP email sent to: {} for mobile: {}", recipientEmail, mobileNumber);
            } else {
                log.info("=== OTP EMAIL CONTENT ===");
                log.info("Mobile: {}", mobileNumber);
                log.info("OTP: {}", otpCode);
                log.info("Purpose: {}", purpose);
                log.info("Valid for: {} minutes", validityMinutes);
                log.info("========================");
            }

        } catch (Exception e) {
            log.error("Failed to send OTP email for mobile: {}", mobileNumber, e);
        }
    }

    private String lookupUserEmail(String mobileNumber) {
        try {
            return userRepository.findByMobileNumber(mobileNumber)
                    .map(user -> user.getEmail())
                    .orElse(null);
        } catch (Exception e) {
            log.error("Error looking up user email for mobile: {}", mobileNumber, e);
            return null;
        }
    }

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
            "NammaOoru Team",
            purposeText, otpCode, validityMinutes
        );
    }

    private String getPurposeDisplayText(MobileOtp.OtpPurpose purpose) {
        return switch (purpose) {
            case REGISTRATION -> "account registration";
            case LOGIN -> "login";
            case FORGOT_PASSWORD -> "password reset";
            case CHANGE_MOBILE -> "mobile number change";
            case VERIFY_MOBILE -> "mobile verification";
            case ORDER_CONFIRMATION -> "order confirmation";
            case ACCOUNT_VERIFICATION -> "account verification";
            case PASSWORD_RESET -> "password reset";
        };
    }

    @Transactional
    public void cleanupExpiredOtps() {
        LocalDateTime now = LocalDateTime.now();
        otpRepository.deactivateExpiredOtps(now);

        LocalDateTime cutoff = now.minusDays(7);
        otpRepository.deleteOldOtps(cutoff);

        log.info("Cleaned up expired OTPs");
    }

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

    public boolean hasVerifiedOtp(String mobileNumber, String purpose, String deviceId) {
        try {
            LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);

            MobileOtp.OtpPurpose otpPurpose = MobileOtp.OtpPurpose.valueOf(purpose.toUpperCase());

            Optional<MobileOtp> verifiedOtp = otpRepository.findTopByMobileNumberAndPurposeAndVerifiedAtNotNullOrderByVerifiedAtDesc(
                mobileNumber, otpPurpose);

            if (verifiedOtp.isPresent()) {
                MobileOtp otp = verifiedOtp.get();

                if (otp.getVerifiedAt().isAfter(oneHourAgo)) {
                    if (deviceId != null && !deviceId.isEmpty()) {
                        if (deviceId.equals(otp.getDeviceId())) {
                            return true;
                        } else {
                            log.warn("Device ID mismatch for verified OTP. Expected: {}, Found: {}",
                                deviceId, otp.getDeviceId());
                            return false;
                        }
                    }
                    return true;
                }
            }

            return false;

        } catch (Exception e) {
            log.error("Error checking verified OTP for mobile: {}", mobileNumber, e);
            return false;
        }
    }

    public void sendOtpViaSms(String mobileNumber, String otp, String purpose) {
        log.info("Sending pre-generated OTP via SMS to: {} for purpose: {}", mobileNumber, purpose);
        try {
            if ("PASSWORD_RESET".equalsIgnoreCase(purpose) || "FORGOT_PASSWORD".equalsIgnoreCase(purpose)) {
                smsService.sendForgotPasswordOtpSms(mobileNumber, otp, otpExpiryMinutes);
            } else {
                smsService.sendOtpSms(mobileNumber, otp, otpExpiryMinutes);
            }
            log.info("OTP sent successfully via SMS to: {}", mobileNumber);
        } catch (Exception e) {
            log.error("Failed to send OTP via SMS to: {}", mobileNumber, e);
            throw new RuntimeException("Failed to send OTP via SMS: " + e.getMessage(), e);
        }
    }
}
