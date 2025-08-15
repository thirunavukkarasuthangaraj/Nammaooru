package com.shopmanagement.auth.service;

import com.shopmanagement.auth.entity.PasswordResetToken;
import com.shopmanagement.auth.repository.PasswordResetTokenRepository;
import com.shopmanagement.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class PasswordResetService {

    private final PasswordResetTokenRepository tokenRepository;
    private final EmailService emailService;

    public void initiatePasswordReset(String usernameOrEmail) {
        log.info("Initiating password reset for: {}", usernameOrEmail);
        
        // Check if it's email or username
        boolean isEmail = usernameOrEmail.contains("@");
        
        // For demo purposes, we'll assume this is a valid user
        // In real implementation, you'd validate against your user repository
        String username = isEmail ? extractUsernameFromEmail(usernameOrEmail) : usernameOrEmail;
        String email = isEmail ? usernameOrEmail : getEmailForUsername(username);
        
        if (email == null) {
            log.warn("No email found for user: {}", usernameOrEmail);
            return; // Don't reveal that user doesn't exist
        }
        
        // Check if there's already a valid token for this user
        if (tokenRepository.existsByUsernameAndUsedFalseAndExpiryDateAfter(username, LocalDateTime.now())) {
            log.info("Valid password reset token already exists for user: {}", username);
            return; // Don't create multiple tokens
        }
        
        // Invalidate any existing tokens for this user
        tokenRepository.markAllTokensAsUsedForUser(username);
        
        // Generate new reset token
        String resetToken = generateSecureToken();
        
        PasswordResetToken token = PasswordResetToken.builder()
                .token(resetToken)
                .username(username)
                .email(email)
                .expiryDate(LocalDateTime.now().plusMinutes(30))
                .used(false)
                .build();
        
        tokenRepository.save(token);
        
        // Send password reset email
        try {
            emailService.sendPasswordResetEmail(email, username, resetToken);
            log.info("Password reset email sent successfully to: {}", email);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", email, e);
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

    public boolean validateResetToken(String token) {
        Optional<PasswordResetToken> resetToken = tokenRepository.findByToken(token);
        
        if (resetToken.isEmpty()) {
            log.warn("Password reset token not found: {}", token);
            return false;
        }
        
        PasswordResetToken tokenEntity = resetToken.get();
        
        if (!tokenEntity.isValid()) {
            log.warn("Password reset token is invalid or expired: {}", token);
            return false;
        }
        
        return true;
    }

    public boolean resetPassword(String token, String newPassword) {
        Optional<PasswordResetToken> resetToken = tokenRepository.findByToken(token);
        
        if (resetToken.isEmpty()) {
            log.warn("Password reset token not found: {}", token);
            return false;
        }
        
        PasswordResetToken tokenEntity = resetToken.get();
        
        if (!tokenEntity.isValid()) {
            log.warn("Password reset token is invalid or expired: {}", token);
            return false;
        }
        
        try {
            // Here you would update the user's password in your user repository
            // For now, we'll just mark the token as used
            tokenEntity.setUsed(true);
            tokenRepository.save(tokenEntity);
            
            log.info("Password reset successfully for user: {}", tokenEntity.getUsername());
            return true;
        } catch (Exception e) {
            log.error("Failed to reset password for user: {}", tokenEntity.getUsername(), e);
            return false;
        }
    }

    @Async
    @Scheduled(fixedRate = 3600000) // Run every hour
    public void cleanupExpiredTokens() {
        log.info("Cleaning up expired password reset tokens");
        tokenRepository.deleteExpiredTokens(LocalDateTime.now());
    }

    private String generateSecureToken() {
        return UUID.randomUUID().toString().replace("-", "") + 
               System.currentTimeMillis();
    }

    private String extractUsernameFromEmail(String email) {
        // In real implementation, you'd query your user repository
        // For demo, we'll just use email prefix
        return email.substring(0, email.indexOf("@"));
    }

    private String getEmailForUsername(String username) {
        // In real implementation, you'd query your user repository
        // For demo, we'll return a mock email
        return username + "@example.com";
    }
}