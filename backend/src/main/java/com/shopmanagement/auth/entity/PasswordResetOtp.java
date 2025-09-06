package com.shopmanagement.auth.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "password_reset_otps")
public class PasswordResetOtp {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String otp;
    
    @Column(nullable = false)
    private LocalDateTime expiryTime;
    
    @Column(nullable = false)
    @Builder.Default
    private Boolean used = false;
    
    @Column(nullable = false)
    @Builder.Default
    private Integer attempts = 0;
    
    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
    
    public boolean isValid() {
        return !used && LocalDateTime.now().isBefore(expiryTime) && attempts < 5;
    }
    
    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiryTime);
    }
    
    public void incrementAttempts() {
        this.attempts++;
    }
}