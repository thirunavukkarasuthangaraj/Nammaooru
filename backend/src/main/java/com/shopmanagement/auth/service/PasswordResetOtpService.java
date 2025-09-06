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
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    public boolean sendPasswordResetOtp(String email) {
        try {
            // Check if user exists
            Optional<User> user = userRepository.findByEmail(email);
            if (user.isEmpty()) {
                log.info("Password reset requested for non-existent email: {}", email);
                return true; // Don't reveal that user doesn't exist
            }

            // Rate limiting - max 3 OTP requests per hour
            long recentRequests = otpRepository.countOtpRequestsByEmailSince(
                email, LocalDateTime.now().minusHours(1));
            if (recentRequests >= 3) {
                log.warn("Too many OTP requests for email: {}", email);
                return false;
            }

            // Check if there's already a valid OTP
            if (otpRepository.existsByEmailAndUsedFalseAndExpiryTimeAfter(email, LocalDateTime.now())) {
                log.info("Valid OTP already exists for email: {}", email);
                return true; // Don't send multiple OTPs
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

            // Send OTP email
            emailService.sendPasswordResetOtpEmail(email, user.get().getUsername(), otp);
            
            log.info("Password reset OTP sent to: {}", email);
            return true;

        } catch (Exception e) {
            log.error("Error sending password reset OTP to: {}", email, e);
            return false;
        }
    }

    public boolean verifyPasswordResetOtp(String email, String otp) {
        try {
            Optional<PasswordResetOtp> otpEntity = otpRepository
                .findByEmailAndOtpAndUsedFalseAndExpiryTimeAfter(email, otp, LocalDateTime.now());

            if (otpEntity.isEmpty()) {
                log.warn("Invalid or expired OTP for email: {}", email);
                
                // Increment attempts for any valid OTP for this email
                Optional<PasswordResetOtp> anyValidOtp = otpRepository
                    .findByEmailAndUsedFalseAndExpiryTimeAfter(email, LocalDateTime.now());
                anyValidOtp.ifPresent(PasswordResetOtp::incrementAttempts);
                
                return false;
            }

            PasswordResetOtp otp1 = otpEntity.get();
            if (!otp1.isValid()) {
                log.warn("OTP is not valid for email: {}", email);
                return false;
            }

            log.info("OTP verified successfully for email: {}", email);
            return true;

        } catch (Exception e) {
            log.error("Error verifying OTP for email: {}", email, e);
            return false;
        }
    }

    public boolean resetPasswordWithOtp(String email, String otp, String newPassword) {
        try {
            // First verify the OTP
            if (!verifyPasswordResetOtp(email, otp)) {
                return false;
            }

            // Find the user
            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isEmpty()) {
                log.warn("User not found for email: {}", email);
                return false;
            }

            User user = userOpt.get();
            
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

            log.info("Password reset successfully for email: {}", email);
            return true;

        } catch (Exception e) {
            log.error("Error resetting password for email: {}", email, e);
            return false;
        }
    }

    public boolean resendPasswordResetOtp(String email) {
        try {
            // Invalidate existing OTPs
            otpRepository.markAllOtpAsUsedForEmail(email);
            
            // Send new OTP
            return sendPasswordResetOtp(email);
            
        } catch (Exception e) {
            log.error("Error resending OTP for email: {}", email, e);
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