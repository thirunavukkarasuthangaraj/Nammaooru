package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.UserPostLimit;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.UserPostLimitService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@Slf4j
public class UserPostLimitController {

    private final UserPostLimitService userPostLimitService;
    private final UserRepository userRepository;

    private static final String[] FEATURE_NAMES = {
        "PARCEL_SERVICE", "MARKETPLACE", "LABOURS", "FARM_PRODUCTS", "TRAVELS"
    };

    // ---- Admin endpoints ----

    @GetMapping("/api/admin/post-limits")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<UserPostLimit>>> getAllLimits() {
        try {
            List<UserPostLimit> limits = userPostLimitService.getAllLimits();
            return ResponseUtil.success(limits, "Post limits retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching post limits", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/api/admin/post-limits/user/{userId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<UserPostLimit>>> getLimitsByUser(@PathVariable Long userId) {
        try {
            List<UserPostLimit> limits = userPostLimitService.getLimitsByUserId(userId);
            return ResponseUtil.success(limits, "User post limits retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching post limits for user: {}", userId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/api/admin/post-limits")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserPostLimit>> createOrUpdateLimit(@RequestBody UserPostLimit request) {
        try {
            UserPostLimit limit = userPostLimitService.createOrUpdate(
                    request.getUserId(), request.getFeatureName(), request.getMaxPosts());
            return ResponseUtil.success(limit, "Post limit saved successfully");
        } catch (Exception e) {
            log.error("Error saving post limit", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/api/admin/post-limits/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteLimit(@PathVariable Long id) {
        try {
            userPostLimitService.delete(id);
            return ResponseUtil.success(null, "Post limit deleted successfully");
        } catch (Exception e) {
            log.error("Error deleting post limit: {}", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    // ---- User endpoint (for mobile) ----

    @GetMapping("/api/post-limits/my")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> getMyLimits(Authentication authentication) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Map<String, Integer> limits = new HashMap<>();
            for (String featureName : FEATURE_NAMES) {
                limits.put(featureName, userPostLimitService.getEffectiveLimit(user.getId(), featureName));
            }
            return ResponseUtil.success(limits, "Effective limits retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my post limits", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
