package com.shopmanagement.service;

import com.shopmanagement.entity.FeatureConfig;
import com.shopmanagement.entity.UserPostLimit;
import com.shopmanagement.repository.FeatureConfigRepository;
import com.shopmanagement.repository.UserPostLimitRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserPostLimitService {

    private final UserPostLimitRepository userPostLimitRepository;
    private final FeatureConfigRepository featureConfigRepository;

    /**
     * Returns the effective post limit for a user+feature.
     * Priority: user-specific override > global FeatureConfig limit.
     * 0 means unlimited.
     */
    public int getEffectiveLimit(Long userId, String featureName) {
        // Check user-specific override first
        Optional<UserPostLimit> userLimit = userPostLimitRepository.findByUserIdAndFeatureName(userId, featureName);
        if (userLimit.isPresent()) {
            return userLimit.get().getMaxPosts();
        }

        // Fall back to global limit from FeatureConfig
        Optional<FeatureConfig> featureConfig = featureConfigRepository.findByFeatureName(featureName);
        if (featureConfig.isPresent() && featureConfig.get().getMaxPostsPerUser() != null) {
            return featureConfig.get().getMaxPostsPerUser();
        }

        return 0; // unlimited
    }

    @Transactional(readOnly = true)
    public List<UserPostLimit> getAllLimits() {
        return userPostLimitRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<UserPostLimit> getLimitsByUserId(Long userId) {
        return userPostLimitRepository.findByUserId(userId);
    }

    @Transactional(readOnly = true)
    public List<UserPostLimit> getLimitsByFeatureName(String featureName) {
        return userPostLimitRepository.findByFeatureName(featureName);
    }

    @Transactional
    public UserPostLimit createOrUpdate(Long userId, String featureName, Integer maxPosts) {
        Optional<UserPostLimit> existing = userPostLimitRepository.findByUserIdAndFeatureName(userId, featureName);
        if (existing.isPresent()) {
            UserPostLimit limit = existing.get();
            limit.setMaxPosts(maxPosts);
            log.info("Updated post limit: userId={}, feature={}, maxPosts={}", userId, featureName, maxPosts);
            return userPostLimitRepository.save(limit);
        }

        UserPostLimit limit = UserPostLimit.builder()
                .userId(userId)
                .featureName(featureName)
                .maxPosts(maxPosts)
                .build();
        log.info("Created post limit: userId={}, feature={}, maxPosts={}", userId, featureName, maxPosts);
        return userPostLimitRepository.save(limit);
    }

    @Transactional
    public void delete(Long id) {
        userPostLimitRepository.deleteById(id);
        log.info("Deleted post limit: id={}", id);
    }
}
