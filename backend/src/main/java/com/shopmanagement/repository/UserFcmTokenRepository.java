package com.shopmanagement.repository;

import com.shopmanagement.entity.UserFcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserFcmTokenRepository extends JpaRepository<UserFcmToken, Long> {

    // Find active tokens for a user
    @Query("SELECT u FROM UserFcmToken u WHERE u.userId = :userId AND u.isActive = true ORDER BY u.updatedAt DESC")
    List<UserFcmToken> findActiveTokensByUserId(@Param("userId") Long userId);

    // Find active tokens for a user (using method name convention)
    List<UserFcmToken> findByUserIdAndIsActiveTrue(Long userId);

    // Find by user and token
    Optional<UserFcmToken> findByUserIdAndFcmToken(Long userId, String fcmToken);

    // Find by token only
    Optional<UserFcmToken> findByFcmToken(String fcmToken);

    // Find by user and device type
    Optional<UserFcmToken> findByUserIdAndDeviceType(Long userId, String deviceType);

    // Deactivate all tokens for a user
    @Modifying
    @Query("UPDATE UserFcmToken u SET u.isActive = false WHERE u.userId = :userId")
    void deactivateAllTokensForUser(@Param("userId") Long userId);

    // Deactivate specific token
    @Modifying
    @Query("UPDATE UserFcmToken u SET u.isActive = false WHERE u.fcmToken = :token")
    void deactivateToken(@Param("token") String token);

    // Find all active tokens for multiple users
    @Query("SELECT u FROM UserFcmToken u WHERE u.userId IN :userIds AND u.isActive = true")
    List<UserFcmToken> findActiveTokensByUserIds(@Param("userIds") List<Long> userIds);

    // Delete old inactive tokens (cleanup)
    @Modifying
    @Query("DELETE FROM UserFcmToken u WHERE u.isActive = false AND u.updatedAt < :cutoffDate")
    void deleteOldInactiveTokens(@Param("cutoffDate") java.time.LocalDateTime cutoffDate);
}