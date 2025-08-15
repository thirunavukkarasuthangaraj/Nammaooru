package com.shopmanagement.auth.repository;

import com.shopmanagement.auth.entity.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    
    Optional<PasswordResetToken> findByToken(String token);
    
    Optional<PasswordResetToken> findByUsernameAndUsedFalse(String username);
    
    Optional<PasswordResetToken> findByEmailAndUsedFalse(String email);
    
    @Modifying
    @Query("DELETE FROM PasswordResetToken p WHERE p.expiryDate < :now")
    void deleteExpiredTokens(@Param("now") LocalDateTime now);
    
    @Modifying
    @Query("UPDATE PasswordResetToken p SET p.used = true WHERE p.username = :username")
    void markAllTokensAsUsedForUser(@Param("username") String username);
    
    boolean existsByUsernameAndUsedFalseAndExpiryDateAfter(String username, LocalDateTime now);
}