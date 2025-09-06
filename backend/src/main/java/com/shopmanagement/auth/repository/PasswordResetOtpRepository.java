package com.shopmanagement.auth.repository;

import com.shopmanagement.auth.entity.PasswordResetOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetOtpRepository extends JpaRepository<PasswordResetOtp, Long> {
    
    Optional<PasswordResetOtp> findByEmailAndOtpAndUsedFalseAndExpiryTimeAfter(
        String email, String otp, LocalDateTime currentTime);
    
    Optional<PasswordResetOtp> findByEmailAndUsedFalseAndExpiryTimeAfter(
        String email, LocalDateTime currentTime);
    
    boolean existsByEmailAndUsedFalseAndExpiryTimeAfter(String email, LocalDateTime currentTime);
    
    @Modifying
    @Query("UPDATE PasswordResetOtp p SET p.used = true WHERE p.email = :email")
    void markAllOtpAsUsedForEmail(@Param("email") String email);
    
    @Modifying
    @Query("DELETE FROM PasswordResetOtp p WHERE p.expiryTime < :currentTime")
    void deleteExpiredOtps(@Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT COUNT(p) FROM PasswordResetOtp p WHERE p.email = :email AND p.createdAt > :since")
    long countOtpRequestsByEmailSince(@Param("email") String email, @Param("since") LocalDateTime since);
}