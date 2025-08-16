package com.shopmanagement.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "mobile_otps")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MobileOtp {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 15)
    @NotBlank(message = "Mobile number is required")
    private String mobileNumber;
    
    @Column(nullable = false, length = 6)
    @NotBlank(message = "OTP is required")
    private String otpCode;
    
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private OtpPurpose purpose;
    
    @Column(nullable = false)
    private LocalDateTime expiresAt;
    
    @Column(nullable = false)
    @Builder.Default
    private Boolean isUsed = false;
    
    @Column(nullable = false)
    @Builder.Default
    private Boolean isActive = true;
    
    @Column(nullable = false)
    @Builder.Default
    private Integer attemptCount = 0;
    
    @Column(nullable = false)
    @Builder.Default
    private Integer maxAttempts = 3;
    
    // Device and session information for security
    @Column(length = 100)
    private String deviceId;
    
    @Column(length = 20)
    private String deviceType;
    
    @Column(length = 50)
    private String appVersion;
    
    @Column(length = 45)
    private String ipAddress;
    
    @Column(length = 100)
    private String sessionId;
    
    // Verification details
    @Column
    private LocalDateTime verifiedAt;
    
    @Column(length = 100)
    private String verifiedBy;
    
    // Audit fields
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(nullable = false)
    @Builder.Default
    private String createdBy = "mobile-app";
    
    // OTP Purposes
    public enum OtpPurpose {
        REGISTRATION,
        LOGIN,
        FORGOT_PASSWORD,
        CHANGE_MOBILE,
        VERIFY_MOBILE,
        ORDER_CONFIRMATION,
        ACCOUNT_VERIFICATION
    }
    
    // Helper methods
    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }
    
    public boolean isValid() {
        return isActive && !isUsed && !isExpired() && attemptCount < maxAttempts;
    }
    
    public boolean canAttempt() {
        return attemptCount < maxAttempts && !isUsed && !isExpired();
    }
    
    public void incrementAttempt() {
        this.attemptCount++;
        if (this.attemptCount >= this.maxAttempts) {
            this.isActive = false;
        }
    }
    
    public void markAsUsed() {
        this.isUsed = true;
        this.verifiedAt = LocalDateTime.now();
    }
    
    public void markAsExpired() {
        this.isActive = false;
    }
    
    public long getMinutesUntilExpiry() {
        if (isExpired()) {
            return 0;
        }
        return java.time.Duration.between(LocalDateTime.now(), expiresAt).toMinutes();
    }
    
    public long getSecondsUntilExpiry() {
        if (isExpired()) {
            return 0;
        }
        return java.time.Duration.between(LocalDateTime.now(), expiresAt).getSeconds();
    }
}