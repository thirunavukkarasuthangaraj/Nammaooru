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
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllLimits() {
        try {
            List<UserPostLimit> limits = userPostLimitService.getAllLimits();
            List<Map<String, Object>> enrichedLimits = limits.stream().map(limit -> {
                Map<String, Object> map = new HashMap<>();
                map.put("id", limit.getId());
                map.put("userId", limit.getUserId());
                map.put("featureName", limit.getFeatureName());
                map.put("maxPosts", limit.getMaxPosts());
                map.put("createdAt", limit.getCreatedAt());
                map.put("updatedAt", limit.getUpdatedAt());
                // Enrich with user info
                userRepository.findById(limit.getUserId()).ifPresent(user -> {
                    map.put("userName", (user.getFirstName() != null ? user.getFirstName() : "") +
                            (user.getLastName() != null ? " " + user.getLastName() : ""));
                    map.put("mobileNumber", user.getMobileNumber());
                    map.put("email", user.getEmail());
                });
                return map;
            }).collect(java.util.stream.Collectors.toList());
            return ResponseUtil.success(enrichedLimits, "Post limits retrieved successfully");
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
    public ResponseEntity<ApiResponse<UserPostLimit>> createOrUpdateLimit(@RequestBody Map<String, Object> request) {
        try {
            Long userId;
            String userIdentifier = request.get("userIdentifier") != null ? request.get("userIdentifier").toString().trim() : null;

            if (userIdentifier != null && !userIdentifier.isEmpty()) {
                // Look up user by mobile number or email
                User user = userRepository.findByMobileNumber(userIdentifier)
                        .or(() -> userRepository.findByEmail(userIdentifier))
                        .orElseThrow(() -> new RuntimeException("No user found with mobile number or email: " + userIdentifier));
                userId = user.getId();
            } else if (request.get("userId") != null) {
                userId = Long.parseLong(request.get("userId").toString());
            } else {
                throw new RuntimeException("Please provide mobile number or email");
            }

            String featureName = request.get("featureName").toString();
            Integer maxPosts = Integer.parseInt(request.get("maxPosts").toString());

            UserPostLimit limit = userPostLimitService.createOrUpdate(userId, featureName, maxPosts);
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

    @GetMapping("/api/admin/post-limits/lookup-user")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> lookupUser(@RequestParam String query) {
        try {
            String trimmedQuery = query.trim();
            User user = userRepository.findByMobileNumber(trimmedQuery)
                    .or(() -> userRepository.findByEmail(trimmedQuery))
                    .orElseThrow(() -> new RuntimeException("No user found with mobile number or email: " + trimmedQuery));

            Map<String, Object> result = new HashMap<>();
            result.put("id", user.getId());
            result.put("firstName", user.getFirstName());
            result.put("lastName", user.getLastName());
            result.put("mobileNumber", user.getMobileNumber());
            result.put("email", user.getEmail());
            return ResponseUtil.success(result, "User found");
        } catch (Exception e) {
            log.error("Error looking up user: {}", query, e);
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
