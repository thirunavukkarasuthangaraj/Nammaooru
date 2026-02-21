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

    private static final String GLOBAL_COUNT_QUERY =
        "SELECT " +
        "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED'))";

    /**
     * Checks if user has already posted anything across ALL modules.
     * One user is allowed only 1 free post overall.
     * Throws LIMIT_REACHED if limit exceeded and no valid paid token.
     */
    public void checkGlobalPostLimit(Long userId, Long paidTokenId) {
        Query query = entityManager.createNativeQuery(GLOBAL_COUNT_QUERY);
        query.setParameter("uid", userId);
        long totalActiveCount = ((Number) query.getSingleResult()).longValue();

        if (totalActiveCount >= 1) {
            if (paidTokenId == null) {
                throw new RuntimeException("LIMIT_REACHED");
            }
            if (!postPaymentService.hasValidToken(paidTokenId, userId)) {
                throw new RuntimeException("Invalid or expired payment token");
            }
        }
    }
}
