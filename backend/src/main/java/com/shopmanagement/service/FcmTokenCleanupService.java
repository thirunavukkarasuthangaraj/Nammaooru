package com.shopmanagement.service;

import com.shopmanagement.repository.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Service to clean up old/invalid FCM tokens automatically.
 * This prevents notification failures due to stale tokens.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FcmTokenCleanupService {

    private final UserFcmTokenRepository userFcmTokenRepository;

    /**
     * Clean up inactive FCM tokens older than 7 days.
     * Runs every day at 3:00 AM.
     */
    @Scheduled(cron = "0 0 3 * * ?") // 3:00 AM every day
    @Transactional
    public void cleanupOldInactiveTokens() {
        try {
            LocalDateTime cutoffDate = LocalDateTime.now().minusDays(7);
            log.info("🧹 Starting FCM token cleanup. Removing inactive tokens older than: {}", cutoffDate);

            userFcmTokenRepository.deleteOldInactiveTokens(cutoffDate);

            log.info("✅ FCM token cleanup completed successfully");
        } catch (Exception e) {
            log.error("❌ Error during FCM token cleanup: {}", e.getMessage(), e);
        }
    }

    /**
     * Clean up duplicate tokens - keep only the latest active token per user per device.
     * Runs every 6 hours.
     */
    @Scheduled(fixedRate = 21600000, initialDelay = 60000) // 6 hours, start after 1 minute
    @Transactional
    public void cleanupDuplicateTokens() {
        try {
            log.info("🔄 Starting duplicate FCM token cleanup...");

            // This query deactivates older duplicate tokens, keeping only the newest one per user
            // We do this by finding users with multiple active tokens and deactivating all but the newest
            int deactivatedCount = deactivateOlderDuplicateTokens();

            if (deactivatedCount > 0) {
                log.info("✅ Deactivated {} duplicate FCM tokens", deactivatedCount);
            } else {
                log.debug("✅ No duplicate FCM tokens found");
            }
        } catch (Exception e) {
            log.error("❌ Error during duplicate FCM token cleanup: {}", e.getMessage(), e);
        }
    }

    /**
     * Deactivates older duplicate tokens, keeping only the newest active token per user.
     * Returns the count of deactivated tokens.
     */
    private int deactivateOlderDuplicateTokens() {
        // Get all active tokens grouped by user
        var allActiveTokens = userFcmTokenRepository.findAll().stream()
                .filter(token -> Boolean.TRUE.equals(token.getIsActive()))
                .toList();

        // Group by user_id
        var tokensByUser = allActiveTokens.stream()
                .collect(java.util.stream.Collectors.groupingBy(
                        token -> token.getUserId(),
                        java.util.stream.Collectors.toList()
                ));

        int deactivatedCount = 0;

        for (var entry : tokensByUser.entrySet()) {
            var userTokens = entry.getValue();

            // If user has more than one active token, keep only the newest
            if (userTokens.size() > 1) {
                // Sort by updatedAt descending (newest first)
                userTokens.sort((a, b) -> {
                    if (a.getUpdatedAt() == null) return 1;
                    if (b.getUpdatedAt() == null) return -1;
                    return b.getUpdatedAt().compareTo(a.getUpdatedAt());
                });

                // Deactivate all except the first (newest) one
                for (int i = 1; i < userTokens.size(); i++) {
                    var token = userTokens.get(i);
                    token.setIsActive(false);
                    userFcmTokenRepository.save(token);
                    deactivatedCount++;
                    log.debug("Deactivated older token for user {}: {}", entry.getKey(), token.getId());
                }
            }
        }

        return deactivatedCount;
    }
}
