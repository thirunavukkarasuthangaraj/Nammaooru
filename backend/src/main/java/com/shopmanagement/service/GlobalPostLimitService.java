package com.shopmanagement.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class GlobalPostLimitService {

    private final EntityManager entityManager;
    private final PostPaymentService postPaymentService;
    private final SettingService settingService;

    private static final String GLOBAL_COUNT_QUERY =
        "SELECT " +
        "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM womens_corner_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED'))";

    /**
     * Checks if user has exceeded the global free post limit across ALL modules.
     * The limit is configurable via the 'global.free_post_limit' setting.
     *   0  = no free posts at all, every post requires payment
     *   1  = first post free, then pay (default)
     *   N  = N free posts, then pay
     *  -1  = unlimited, no payment required
     * Throws LIMIT_REACHED if limit exceeded and no valid paid token.
     */
    public void checkGlobalPostLimit(Long userId, Long paidTokenId) {
        int freePostLimit = Integer.parseInt(
                settingService.getSettingValue("global.free_post_limit", "1"));

        // Negative means unlimited — skip the check entirely
        if (freePostLimit < 0) {
            return;
        }

        // 0 means no free posts — always require payment
        if (freePostLimit == 0) {
            if (paidTokenId == null) {
                throw new RuntimeException("LIMIT_REACHED");
            }
            if (!postPaymentService.hasValidToken(paidTokenId, userId)) {
                throw new RuntimeException("Invalid or expired payment token");
            }
            return;
        }

        Query query = entityManager.createNativeQuery(GLOBAL_COUNT_QUERY);
        query.setParameter("uid", userId);
        long totalActiveCount = ((Number) query.getSingleResult()).longValue();

        if (totalActiveCount >= freePostLimit) {
            if (paidTokenId == null) {
                throw new RuntimeException("LIMIT_REACHED");
            }
            if (!postPaymentService.hasValidToken(paidTokenId, userId)) {
                throw new RuntimeException("Invalid or expired payment token");
            }
        }
    }
}
