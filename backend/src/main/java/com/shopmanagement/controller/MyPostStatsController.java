package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.SettingService;
import com.shopmanagement.service.UserPostLimitService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@Slf4j
public class MyPostStatsController {

    private final EntityManager entityManager;
    private final UserRepository userRepository;
    private final UserPostLimitService userPostLimitService;
    private final SettingService settingService;

    private static final String[] FEATURE_NAMES = {
        "MARKETPLACE", "FARM_PRODUCTS", "LABOURS", "TRAVELS",
        "PARCEL_SERVICE", "RENTAL", "REAL_ESTATE"
    };

    private static final Map<String, String> DURATION_SETTING_KEYS = Map.of(
        "MARKETPLACE", "marketplace.post.duration_days",
        "FARM_PRODUCTS", "farm_products.post.duration_days",
        "LABOURS", "labours.post.duration_days",
        "TRAVELS", "travels.post.duration_days",
        "PARCEL_SERVICE", "parcel_service.post.duration_days",
        "RENTAL", "rental.post.duration_days",
        "REAL_ESTATE", "real_estate.post.duration_days"
    );

    private static final Map<String, String> DURATION_DEFAULTS = Map.of(
        "MARKETPLACE", "30",
        "FARM_PRODUCTS", "60",
        "LABOURS", "60",
        "TRAVELS", "30",
        "PARCEL_SERVICE", "60",
        "RENTAL", "30",
        "REAL_ESTATE", "90"
    );

    private static final String COUNT_QUERY =
        "SELECT " +
        "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status != 'DELETED') AS marketplace_total, " +
        "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS marketplace_paid, " +
        "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status != 'DELETED') AS farmer_total, " +
        "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS farmer_paid, " +
        "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status != 'DELETED') AS labour_total, " +
        "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS labour_paid, " +
        "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status != 'DELETED') AS travel_total, " +
        "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS travel_paid, " +
        "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status != 'DELETED') AS parcel_total, " +
        "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS parcel_paid, " +
        "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status != 'DELETED') AS rental_total, " +
        "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS rental_paid, " +
        "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status != 'DELETED') AS realestate_total, " +
        "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status != 'DELETED' AND is_paid = true) AS realestate_paid";

    @GetMapping("/api/posts/my-stats")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMyPostStats() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));
            Long userId = user.getId();

            // Single native query for all 7 module counts
            Query query = entityManager.createNativeQuery(COUNT_QUERY);
            query.setParameter("uid", userId);
            Object[] row = (Object[]) query.getSingleResult();

            Map<String, Map<String, Integer>> counts = new LinkedHashMap<>();
            counts.put("MARKETPLACE", buildCounts(row, 0));
            counts.put("FARM_PRODUCTS", buildCounts(row, 2));
            counts.put("LABOURS", buildCounts(row, 4));
            counts.put("TRAVELS", buildCounts(row, 6));
            counts.put("PARCEL_SERVICE", buildCounts(row, 8));
            counts.put("RENTAL", buildCounts(row, 10));
            counts.put("REAL_ESTATE", buildCounts(row, 12));

            // Post limits
            Map<String, Integer> limits = new HashMap<>();
            for (String featureName : FEATURE_NAMES) {
                limits.put(featureName, userPostLimitService.getEffectiveLimit(userId, featureName));
            }

            // Pricing config from Settings DB
            String globalDefaultPrice = settingService.getSettingValue("paid_post.price", "15");
            Map<String, Map<String, Object>> pricing = new LinkedHashMap<>();
            for (String featureName : FEATURE_NAMES) {
                int price = Integer.parseInt(
                    settingService.getSettingValue("paid_post.price." + featureName, globalDefaultPrice));
                String durationKey = DURATION_SETTING_KEYS.getOrDefault(featureName, "marketplace.post.duration_days");
                String durationDefault = DURATION_DEFAULTS.getOrDefault(featureName, "30");
                int durationDays = Integer.parseInt(
                    settingService.getSettingValue(durationKey, durationDefault));
                double perDayRate = durationDays > 0 ? (double) price / durationDays : 0;

                Map<String, Object> config = new HashMap<>();
                config.put("price", price);
                config.put("durationDays", durationDays);
                config.put("perDayRate", Math.round(perDayRate * 100.0) / 100.0);
                pricing.put(featureName, config);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("counts", counts);
            result.put("limits", limits);
            result.put("pricing", pricing);

            return ResponseUtil.success(result, "Post stats retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching post stats", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Map<String, Integer> buildCounts(Object[] row, int offset) {
        int total = ((Number) row[offset]).intValue();
        int paid = ((Number) row[offset + 1]).intValue();
        Map<String, Integer> map = new HashMap<>();
        map.put("total", total);
        map.put("paid", paid);
        map.put("free", total - paid);
        return map;
    }
}
