package com.shopmanagement.service;

import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Manages the user <-> device <-> FCM-token association lifecycle.
 *
 * Invariant: an FCM token identifies one physical device, so at most one user
 * may have an ACTIVE mapping for it at any time. Firebase often returns the
 * same token after logout/login (onNewToken never fires), so registration must
 * re-associate the token with whoever is currently authenticated.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FcmTokenService {

    private final UserFcmTokenRepository userFcmTokenRepository;

    /**
     * Idempotent upsert of the token mapping for the authenticated user.
     * Any ACTIVE mapping of the same token to a different user (previous login
     * on the same device) is deactivated first.
     */
    @Transactional
    public UserFcmToken registerToken(Long userId, FcmTokenRequest request) {
        String fcmToken = request.getFcmToken();
        if (fcmToken == null || fcmToken.isBlank()) {
            throw new IllegalArgumentException("fcmToken is required");
        }

        List<UserFcmToken> tokenRows = userFcmTokenRepository.findAllByFcmToken(fcmToken);

        // Re-associate: same device token must not stay active for a previous user
        for (UserFcmToken row : tokenRows) {
            if (!row.getUserId().equals(userId) && Boolean.TRUE.equals(row.getIsActive())) {
                row.setIsActive(false);
                userFcmTokenRepository.save(row);
                log.info("FCM token re-associated: deactivated stale mapping of user {} (token now belongs to user {})",
                        row.getUserId(), userId);
            }
        }

        List<UserFcmToken> ownRows = tokenRows.stream()
                .filter(row -> row.getUserId().equals(userId))
                .toList();

        UserFcmToken entity;
        if (!ownRows.isEmpty()) {
            // Reuse the existing row; deactivate historical duplicates for the same (user, token)
            entity = ownRows.get(0);
            for (int i = 1; i < ownRows.size(); i++) {
                UserFcmToken duplicate = ownRows.get(i);
                if (Boolean.TRUE.equals(duplicate.getIsActive())) {
                    duplicate.setIsActive(false);
                    userFcmTokenRepository.save(duplicate);
                }
            }
        } else {
            // Token rotated by Firebase: deactivate this user's old tokens for the same device
            if (request.getDeviceId() != null) {
                userFcmTokenRepository.findByUserIdAndIsActiveTrue(userId).stream()
                        .filter(row -> request.getDeviceId().equals(row.getDeviceId()))
                        .forEach(row -> {
                            row.setIsActive(false);
                            userFcmTokenRepository.save(row);
                        });
            }
            entity = new UserFcmToken();
            entity.setUserId(userId);
            entity.setFcmToken(fcmToken);
        }

        entity.setIsActive(true);
        entity.setUpdatedAt(LocalDateTime.now());
        if (request.getDeviceType() != null) {
            entity.setDeviceType(request.getDeviceType());
        } else if (entity.getDeviceType() == null) {
            entity.setDeviceType("android");
        }
        if (request.getDeviceId() != null) {
            entity.setDeviceId(request.getDeviceId());
        }

        UserFcmToken saved = userFcmTokenRepository.save(entity);
        log.info("FCM token registered for current user {} (deviceType: {})", userId, saved.getDeviceType());
        return saved;
    }

    /**
     * Removes (deactivates) the association between the given token and user.
     * Called on logout; the token itself stays valid on the device.
     */
    @Transactional
    public void deactivateToken(Long userId, String fcmToken) {
        List<UserFcmToken> rows = userFcmTokenRepository.findAllByUserIdAndFcmToken(userId, fcmToken);
        boolean any = false;
        for (UserFcmToken row : rows) {
            if (Boolean.TRUE.equals(row.getIsActive())) {
                row.setIsActive(false);
                userFcmTokenRepository.save(row);
                any = true;
            }
        }
        if (any) {
            log.info("FCM token association removed during logout for user {}", userId);
        } else {
            log.info("FCM logout: no active token mapping found for user {}", userId);
        }
    }
}
