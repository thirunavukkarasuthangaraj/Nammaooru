package com.shopmanagement.service;

import com.shopmanagement.entity.FeatureConfig;
import com.shopmanagement.repository.FeatureConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FeatureConfigService {

    private final FeatureConfigRepository featureConfigRepository;

    public List<FeatureConfig> getVisibleFeatures(double lat, double lng) {
        return featureConfigRepository.findVisibleFeaturesAtLocation(lat, lng);
    }

    public List<FeatureConfig> getAllFeatures() {
        return featureConfigRepository.findAllByOrderByDisplayOrderAsc();
    }

    @Transactional
    public FeatureConfig create(FeatureConfig config) {
        return featureConfigRepository.save(config);
    }

    @Transactional
    public FeatureConfig update(Long id, FeatureConfig updated) {
        FeatureConfig existing = featureConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Feature config not found: " + id));
        existing.setFeatureName(updated.getFeatureName());
        existing.setDisplayName(updated.getDisplayName());
        existing.setDisplayNameTamil(updated.getDisplayNameTamil());
        existing.setIcon(updated.getIcon());
        existing.setColor(updated.getColor());
        existing.setRoute(updated.getRoute());
        existing.setLatitude(updated.getLatitude());
        existing.setLongitude(updated.getLongitude());
        existing.setRadiusKm(updated.getRadiusKm());
        existing.setIsActive(updated.getIsActive());
        existing.setDisplayOrder(updated.getDisplayOrder());
        return featureConfigRepository.save(existing);
    }

    @Transactional
    public void delete(Long id) {
        featureConfigRepository.deleteById(id);
    }

    @Transactional
    public FeatureConfig toggleActive(Long id) {
        FeatureConfig config = featureConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Feature config not found: " + id));
        config.setIsActive(!config.getIsActive());
        return featureConfigRepository.save(config);
    }
}
