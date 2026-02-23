package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.FeatureConfig;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.FeatureConfigRepository;
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

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@Slf4j
public class MyPostStatsController {

    private final EntityManager entityManager;
    private final UserRepository userRepository;
    private final UserPostLimitService userPostLimitService;
    private final SettingService settingService;
    private final FeatureConfigRepository featureConfigRepository;

    // All post-based features with their SQL count subqueries
    // Order matters: each entry produces 2 columns (total, paid) in the SQL result
    private static final String[][] POST_FEATURES = {
        {"MARKETPLACE",     "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"FARM_PRODUCTS",   "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"LABOURS",         "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"TRAVELS",         "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"PARCEL_SERVICE",  "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"RENTAL",          "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"REAL_ESTATE",     "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
        {"WOMENS_CORNER",   "(SELECT COUNT(*) FROM womens_corner_posts WHERE seller_user_id = :uid AND status != 'DELETED')",
                            "(SELECT COUNT(*) FROM womens_corner_posts WHERE seller_user_id = :uid AND status != 'DELETED' AND is_paid = true)"},
    };

    private static final Map<String, String> DURATION_SETTING_KEYS = Map.of(
        "MARKETPLACE", "marketplace.post.duration_days",
        "FARM_PRODUCTS", "farm_products.post.duration_days",
        "LABOURS", "labours.post.duration_days",
        "TRAVELS", "travels.post.duration_days",
        "PARCEL_SERVICE", "parcel_service.post.duration_days",
        "RENTAL", "rental.post.duration_days",
        "REAL_ESTATE", "real_estate.post.duration_days",
        "WOMENS_CORNER", "womens_corner.post.duration_days"
    );

    private static final Map<String, String> DURATION_DEFAULTS = Map.of(
        "MARKETPLACE", "30",
        "FARM_PRODUCTS", "60",
        "LABOURS", "60",
        "TRAVELS", "30",
        "PARCEL_SERVICE", "60",
        "RENTAL", "30",
        "REAL_ESTATE", "90",
        "WOMENS_CORNER", "30"
    );

    @GetMapping("/api/posts/my-stats")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMyPostStats() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));
            Long userId = user.getId();

            // Step 1: Get active features from feature_configs DB
            List<FeatureConfig> activeFeatures = featureConfigRepository.findByIsActiveTrueOrderByDisplayOrderAsc();
            Set<String> activeNames = activeFeatures.stream()
                    .map(FeatureConfig::getFeatureName)
                    .collect(Collectors.toSet());

            // Step 2: Build SQL only for active post features
            List<String[]> activePostFeatures = new ArrayList<>();
            for (String[] pf : POST_FEATURES) {
                if (activeNames.contains(pf[0])) {
                    activePostFeatures.add(pf);
                }
            }

            Map<String, Map<String, Integer>> counts = new LinkedHashMap<>();

            if (!activePostFeatures.isEmpty()) {
                // Build dynamic SQL
                StringBuilder sql = new StringBuilder("SELECT ");
                for (int i = 0; i < activePostFeatures.size(); i++) {
                    if (i > 0) sql.append(", ");
                    sql.append(activePostFeatures.get(i)[1]).append(", ");
                    sql.append(activePostFeatures.get(i)[2]);
                }

                Query query = entityManager.createNativeQuery(sql.toString());
                query.setParameter("uid", userId);
                Object[] row = (Object[]) query.getSingleResult();

                for (int i = 0; i < activePostFeatures.size(); i++) {
                    counts.put(activePostFeatures.get(i)[0], buildCounts(row, i * 2));
                }
            }

            // Step 3: Post limits (only for active features)
            Map<String, Integer> limits = new HashMap<>();
            for (String[] pf : activePostFeatures) {
                limits.put(pf[0], userPostLimitService.getEffectiveLimit(userId, pf[0]));
            }

            // Step 4: Pricing config (only for active features)
            String globalDefaultPrice = settingService.getSettingValue("paid_post.price", "15");
            Map<String, Map<String, Object>> pricing = new LinkedHashMap<>();
            for (String[] pf : activePostFeatures) {
                String featureName = pf[0];
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

            // Step 5: Module metadata from feature_configs (display name, icon, color, route)
            Map<String, Map<String, String>> modules = new LinkedHashMap<>();
            Set<String> postFeatureNames = Arrays.stream(POST_FEATURES)
                    .map(pf -> pf[0])
                    .collect(Collectors.toSet());
            for (FeatureConfig fc : activeFeatures) {
                if (postFeatureNames.contains(fc.getFeatureName())) {
                    Map<String, String> meta = new HashMap<>();
                    meta.put("displayName", fc.getDisplayName());
                    meta.put("displayNameTamil", fc.getDisplayNameTamil());
                    meta.put("icon", fc.getIcon());
                    meta.put("color", fc.getColor());
                    meta.put("route", fc.getRoute());
                    meta.put("imageUrl", fc.getImageUrl());
                    modules.put(fc.getFeatureName(), meta);
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("counts", counts);
            result.put("limits", limits);
            result.put("pricing", pricing);
            result.put("modules", modules);

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
