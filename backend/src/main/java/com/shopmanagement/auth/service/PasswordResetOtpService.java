package com.shopmanagement.auth.service;

import com.shopmanagement.auth.entity.PasswordResetOtp;
import com.shopmanagement.auth.repository.PasswordResetOtpRepository;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class PasswordResetOtpService {

    private final PasswordResetOtpRepository otpRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final com.shopmanagement.service.MobileOtpService mobileOtpService;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    // Helper method to find user by email OR mobile number
    private Optional<User> findUserByIdentifier(String identifier) {
        // Check if identifier is a mobile number (contains only digits and optional +)
        if (identifier.matches("^[+]?[0-9]+$")) {
            return userRepository.findByMobileNumber(identifier);
        } else {
            return userRepository.findByEmail(identifier.toLowerCase());
        }
    }

    // Helper method to get email for storing OTP (we still store by email in the OTP table)
    private String getEmailFromUser(User user) {
        return user.getEmail();
    }

    public boolean sendPasswordResetOtp(String identifier) {
        try {
            // Check if user exists by email OR mobile number
            Optional<User> userOpt = findUserByIdentifier(identifier);
            if (userOpt.isEmpty()) {
                log.info("Password reset requested for non-existent identifier: {}", identifier);
                return true; // Don't reveal that user doesn't exist
            }

            User user = userOpt.get();
            String email = getEmailFromUser(user); // Use email for OTP storage

            // Rate limiting - max 3 OTP requests per hour
            long recentRequests = otpRepository.countOtpRequestsByEmailSince(
                email, LocalDateTime.now().minusHours(1));
            if (recentRequests >= 3) {
                log.warn("Too many OTP requests for email: {}", email);
                return false;
            }

            // Invalidate any existing OTPs for this email
            otpRepository.markAllOtpAsUsedForEmail(email);

            // Generate 6-digit OTP
            String otp = generateSixDigitOtp();

            // Create OTP record
            PasswordResetOtp otpEntity = PasswordResetOtp.builder()
                    .email(email)
                    .otp(otp)
                    .expiryTime(LocalDateTime.now().plusMinutes(10)) // 10 minutes validity
                    .used(false)
                    .attempts(0)
                    .build();

            otpRepository.save(otpEntity);

            // Send OTP based on what the user entered
            boolean isMobileIdentifier = identifier.matches("^[+]?[0-9]+$");

            if (isMobileIdentifier) {
                // User entered phone number → send via SMS
                try {
                    mobileOtpService.sendOtpViaSms(user.getMobileNumber(), otp, "PASSWORD_RESET");
                    log.info("Password reset OTP sent via SMS to: {}", user.getMobileNumber());
                } catch (Exception e) {
                    log.error("Failed to send OTP via SMS", e);
                }
            } else {
                // User entered email → send via email
                try {
                    emailService.sendPasswordResetOtpEmail(email, user.getUsername(), otp);
                    log.info("Password reset OTP sent via email to: {}", email);
                } catch (Exception e) {
                    log.error("Failed to send OTP via email", e);
                }
            }

            log.info("Password reset OTP sent for identifier: {}", identifier);
            return true;

        } catch (Exception e) {
            log.error("Error sending password reset OTP for identifier: {}", identifier, e);
            return false;
        }
    }

    public boolean verifyPasswordResetOtp(String identifier, String otp) {
        try {
            // Find user by identifier and get their email for OTP lookup
            Optional<User> userOpt = findUserByIdentifier(identifier);
            if (userOpt.isEmpty()) {
                log.warn("User not found for identifier: {}", identifier);
                return false;
            }

            String email = getEmailFromUser(userOpt.get());

            Optional<PasswordResetOtp> otpEntity = otpRepository
                .findByEmailAndOtpAndUsedFalseAndExpiryTimeAfter(email, otp, LocalDateTime.now());

            if (otpEntity.isEmpty()) {
                log.warn("Invalid or expired OTP for identifier: {}", identifier);

                // Increment attempts for any valid OTP for this email
                Optional<PasswordResetOtp> anyValidOtp = otpRepository
                    .findByEmailAndUsedFalseAndExpiryTimeAfter(email, LocalDateTime.now());
                anyValidOtp.ifPresent(PasswordResetOtp::incrementAttempts);

                return false;
            }

            PasswordResetOtp otp1 = otpEntity.get();
            if (!otp1.isValid()) {
                log.warn("OTP is not valid for identifier: {}", identifier);
                return false;
            }

            log.info("OTP verified successfully for identifier: {}", identifier);
            return true;

        } catch (Exception e) {
            log.error("Error verifying OTP for identifier: {}", identifier, e);
            return false;
        }
    }

    public boolean resetPasswordWithOtp(String identifier, String otp, String newPassword) {
        try {
            // First verify the OTP
            if (!verifyPasswordResetOtp(identifier, otp)) {
                return false;
            }

            // Find the user by identifier
            Optional<User> userOpt = findUserByIdentifier(identifier);
            if (userOpt.isEmpty()) {
                log.warn("User not found for identifier: {}", identifier);
                return false;
            }

            User user = userOpt.get();
            String email = getEmailFromUser(user);

            // Update the password
            user.setPassword(passwordEncoder.encode(newPassword));
            user.setLastPasswordChange(LocalDateTime.now());
            user.setPasswordChangeRequired(false);
            user.setIsTemporaryPassword(false);

            userRepository.save(user);

            // Mark OTP as used
            Optional<PasswordResetOtp> otpEntity = otpRepository
                .findByEmailAndOtpAndUsedFalseAndExpiryTimeAfter(email, otp, LocalDateTime.now());
            if (otpEntity.isPresent()) {
                PasswordResetOtp otpRecord = otpEntity.get();
                otpRecord.setUsed(true);
                otpRepository.save(otpRecord);
            }

            log.info("Password reset successfully for identifier: {}", identifier);
            return true;

        } catch (Exception e) {
            log.error("Error resetting password for identifier: {}", identifier, e);
            return false;
        }
    }

    public boolean resendPasswordResetOtp(String identifier) {
        try {
            // Find user and get their email
            Optional<User> userOpt = findUserByIdentifier(identifier);
            if (userOpt.isEmpty()) {
                log.warn("User not found for identifier: {}", identifier);
                return true; // Don't reveal user doesn't exist
            }

            String email = getEmailFromUser(userOpt.get());

            // Invalidate existing OTPs
            otpRepository.markAllOtpAsUsedForEmail(email);

            // Send new OTP
            return sendPasswordResetOtp(identifier);

        } catch (Exception e) {
            log.error("Error resending OTP for identifier: {}", identifier, e);
            return false;
        }
    }

    @Scheduled(fixedRate = 3600000) // Run every hour
    public void cleanupExpiredOtps() {
        try {
            log.info("Cleaning up expired password reset OTPs");
            otpRepository.deleteExpiredOtps(LocalDateTime.now());
        } catch (Exception e) {
            log.error("Error cleaning up expired OTPs", e);
        }
    }

    private String generateSixDigitOtp() {
        int otp = 100000 + secureRandom.nextInt(900000); // Generate 6-digit number
        return String.valueOf(otp);
    }
}