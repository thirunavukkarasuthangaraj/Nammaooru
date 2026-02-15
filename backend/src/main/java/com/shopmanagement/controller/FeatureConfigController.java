package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.FeatureConfig;
import com.shopmanagement.service.FeatureConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/feature-config")
@RequiredArgsConstructor
@Slf4j
public class FeatureConfigController {

    private final FeatureConfigService featureConfigService;

    @GetMapping("/visible")
    public ResponseEntity<ApiResponse<List<FeatureConfig>>> getVisibleFeatures(
            @RequestParam double lat,
            @RequestParam double lng) {
        try {
            List<FeatureConfig> features = featureConfigService.getVisibleFeatures(lat, lng);
            return ResponseUtil.success(features, "Visible features retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching visible features", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<FeatureConfig>>> getAllFeatures() {
        try {
            List<FeatureConfig> features = featureConfigService.getAllFeatures();
            return ResponseUtil.success(features, "All feature configs retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching all feature configs", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FeatureConfig>> createFeature(@RequestBody FeatureConfig config) {
        try {
            FeatureConfig created = featureConfigService.create(config);
            return ResponseUtil.success(created, "Feature config created successfully");
        } catch (Exception e) {
            log.error("Error creating feature config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FeatureConfig>> updateFeature(
            @PathVariable Long id,
            @RequestBody FeatureConfig config) {
        try {
            FeatureConfig updated = featureConfigService.update(id, config);
            return ResponseUtil.success(updated, "Feature config updated successfully");
        } catch (Exception e) {
            log.error("Error updating feature config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteFeature(@PathVariable Long id) {
        try {
            featureConfigService.delete(id);
            return ResponseUtil.success(null, "Feature config deleted successfully");
        } catch (Exception e) {
            log.error("Error deleting feature config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/{id}/toggle")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FeatureConfig>> toggleActive(@PathVariable Long id) {
        try {
            FeatureConfig config = featureConfigService.toggleActive(id);
            return ResponseUtil.success(config, "Feature config toggled successfully");
        } catch (Exception e) {
            log.error("Error toggling feature config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
