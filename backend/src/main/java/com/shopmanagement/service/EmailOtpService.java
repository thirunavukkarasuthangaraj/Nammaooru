package com.shopmanagement.service;

import com.shopmanagement.entity.EmailOtp;
import com.shopmanagement.repository.EmailOtpRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailOtpService {

    private final EmailOtpRepository emailOtpRepository;
    private final EmailService emailService;

    private static final int OTP_EXPIRY_MINUTES = 10;
    private static final int MAX_ATTEMPTS_PER_HOUR = 5;

    @Transactional
    public String generateAndSendOtp(String email, String purpose, String userName) {
        // Check rate limiting
        LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
        long recentAttempts = emailOtpRepository.countOtpAttemptsSince(email, purpose, oneHourAgo);
        
        if (recentAttempts >= MAX_ATTEMPTS_PER_HOUR) {
            throw new RuntimeException("Too many OTP requests. Please try again after an hour.");
        }

        // Deactivate all previous active OTPs for this email and purpose
        emailOtpRepository.deactivateAllActiveOtpsByEmailAndPurpose(email, purpose);

        // Generate new 6-digit OTP
        String otpCode = String.valueOf((int) (Math.random() * 900000) + 100000);

        // Create and save new OTP record
        EmailOtp emailOtp = EmailOtp.builder()
                .email(email.trim().toLowerCase())
                .otpCode(otpCode)
                .purpose(purpose.toUpperCase())
                .expiresAt(LocalDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES))
                .isUsed(false)
                .isActive(true)
                .attemptCount(0)
                .build();

        emailOtpRepository.save(emailOtp);

        // Send OTP email
        try {
            if ("REGISTRATION".equals(purpose.toUpperCase())) {
                emailService.sendOtpVerificationEmail(email, userName, otpCode);
            } else if ("PASSWORD_RESET".equals(purpose.toUpperCase())) {
                // You can create a separate template for password reset
                emailService.sendOtpVerificationEmail(email, userName, otpCode);
            }
            
            log.info("OTP sent to email: {} for purpose: {}", email, purpose);
            return "OTP sent successfully";
            
        } catch (Exception e) {
            log.error("Failed to send OTP email to: {}", email, e);
            throw new RuntimeException("Failed to send OTP email");
        }
    }

    @Transactional
    public boolean verifyOtp(String email, String otpCode, String purpose) {
        email = email.trim().toLowerCase();
        purpose = purpose.toUpperCase();

        // Find the OTP record
        Optional<EmailOtp> otpOptional = emailOtpRepository.findByEmailAndOtpCodeAndPurpose(email, otpCode, purpose);

        if (otpOptional.isEmpty()) {
            log.warn("Invalid OTP attempt for email: {} and purpose: {}", email, purpose);
            return false;
        }

        EmailOtp otp = otpOptional.get();

        // Increment attempt count
        otp.incrementAttempt();
        emailOtpRepository.save(otp);

        // Check if OTP is valid
        if (!otp.isValid()) {
            if (otp.isExpired()) {
                log.warn("Expired OTP used for email: {}", email);
            } else if (otp.getIsUsed()) {
                log.warn("Already used OTP attempted for email: {}", email);
            } else {
                log.warn("Inactive OTP attempted for email: {}", email);
            }
            return false;
        }

        // Mark OTP as used
        otp.markAsUsed();
        emailOtpRepository.save(otp);

        log.info("OTP successfully verified for email: {} and purpose: {}", email, purpose);
        return true;
    }

    @Transactional
    public void invalidateAllOtps(String email, String purpose) {
        emailOtpRepository.deactivateAllActiveOtpsByEmailAndPurpose(email.trim().toLowerCase(), purpose.toUpperCase());
    }

    // Cleanup expired OTPs every hour
    @Scheduled(fixedRate = 3600000) // 1 hour in milliseconds
    @Transactional
    public void cleanupExpiredOtps() {
        LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24); // Delete OTPs older than 24 hours
        emailOtpRepository.deleteExpiredOtps(cutoffTime);
        log.info("Cleaned up expired OTPs older than 24 hours");
    }

    public boolean hasActiveOtp(String email, String purpose) {
        return emailOtpRepository.findLatestActiveOtpByEmailAndPurpose(
                email.trim().toLowerCase(),
                purpose.toUpperCase()
        ).isPresent();
    }

    /**
     * Generate OTP without sending email (for cases where we need to use the same OTP for SMS and email)
     */
    @Transactional
    public String generateOtp(String email, String purpose) {
        // Check rate limiting
        LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
        long recentAttempts = emailOtpRepository.countOtpAttemptsSince(email, purpose, oneHourAgo);

        if (recentAttempts >= MAX_ATTEMPTS_PER_HOUR) {
            throw new RuntimeException("Too many OTP requests. Please try again after an hour.");
        }

        // Deactivate all previous active OTPs for this email and purpose
        emailOtpRepository.deactivateAllActiveOtpsByEmailAndPurpose(email, purpose);

        // Generate new 6-digit OTP
        String otpCode = String.valueOf((int) (Math.random() * 900000) + 100000);

        // Create and save new OTP record
        EmailOtp emailOtp = EmailOtp.builder()
                .email(email.trim().toLowerCase())
                .otpCode(otpCode)
                .purpose(purpose.toUpperCase())
                .expiresAt(LocalDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES))
                .isUsed(false)
                .isActive(true)
                .attemptCount(0)
                .build();

        emailOtpRepository.save(emailOtp);

        log.info("OTP generated for email: {} for purpose: {}", email, purpose);
        return otpCode;
    }

    /**
     * Store an existing OTP (for cases where we generate OTP once and want to use it for multiple channels)
     */
    @Transactional
    public void storeOtp(String email, String otpCode, String purpose) {
        // Deactivate all previous active OTPs for this email and purpose
        emailOtpRepository.deactivateAllActiveOtpsByEmailAndPurpose(email, purpose);

        // Create and save new OTP record
        EmailOtp emailOtp = EmailOtp.builder()
                .email(email.trim().toLowerCase())
                .otpCode(otpCode)
                .purpose(purpose.toUpperCase())
                .expiresAt(LocalDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES))
                .isUsed(false)
                .isActive(true)
                .attemptCount(0)
                .build();

        emailOtpRepository.save(emailOtp);

        log.info("OTP stored for email: {} for purpose: {}", email, purpose);
    }
}