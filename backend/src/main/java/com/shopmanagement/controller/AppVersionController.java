package com.shopmanagement.controller;

import com.shopmanagement.entity.AppVersion;
import com.shopmanagement.repository.AppVersionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/app-version")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AppVersionController {

    private final AppVersionRepository appVersionRepository;

    /**
     * Check app version and return update information
     * @param appName - CUSTOMER_APP, SHOP_OWNER_APP, DELIVERY_PARTNER_APP
     * @param platform - ANDROID, IOS
     * @param currentVersion - Current app version (e.g., "1.0.0")
     * @return Update information including whether update is required
     */
    @GetMapping("/check")
    public ResponseEntity<Map<String, Object>> checkVersion(
            @RequestParam String appName,
            @RequestParam String platform,
            @RequestParam String currentVersion
    ) {
        Map<String, Object> response = new HashMap<>();

        AppVersion appVersion = appVersionRepository
                .findByAppNameAndPlatform(appName, platform)
                .orElse(null);

        if (appVersion == null) {
            response.put("updateRequired", false);
            response.put("message", "App version information not found");
            return ResponseEntity.ok(response);
        }

        // Compare versions
        boolean updateRequired = isUpdateRequired(currentVersion, appVersion.getMinimumVersion());
        boolean updateAvailable = isUpdateRequired(currentVersion, appVersion.getCurrentVersion());

        response.put("updateRequired", updateRequired); // Must update (below minimum)
        response.put("updateAvailable", updateAvailable); // Can update (new version available)
        response.put("isMandatory", appVersion.getIsMandatory());
        response.put("currentVersion", appVersion.getCurrentVersion());
        response.put("minimumVersion", appVersion.getMinimumVersion());
        response.put("updateUrl", appVersion.getUpdateUrl());
        response.put("releaseNotes", appVersion.getReleaseNotes());

        return ResponseEntity.ok(response);
    }

    /**
     * Compare semantic versions (e.g., "1.0.0" vs "1.2.0")
     * Returns true if currentVersion is less than requiredVersion
     */
    private boolean isUpdateRequired(String currentVersion, String requiredVersion) {
        try {
            String[] current = currentVersion.split("\\.");
            String[] required = requiredVersion.split("\\.");

            for (int i = 0; i < Math.max(current.length, required.length); i++) {
                int currentPart = i < current.length ? Integer.parseInt(current[i]) : 0;
                int requiredPart = i < required.length ? Integer.parseInt(required[i]) : 0;

                if (currentPart < requiredPart) {
                    return true; // Update required
                } else if (currentPart > requiredPart) {
                    return false; // Current version is newer
                }
            }

            return false; // Versions are equal
        } catch (Exception e) {
            return false; // If version comparison fails, don't force update
        }
    }

    /**
     * Admin endpoint to update app version (for future use)
     */
    @PutMapping("/update")
    public ResponseEntity<AppVersion> updateVersion(@RequestBody AppVersion appVersion) {
        AppVersion existing = appVersionRepository
                .findByAppNameAndPlatform(appVersion.getAppName(), appVersion.getPlatform())
                .orElse(appVersion);

        existing.setCurrentVersion(appVersion.getCurrentVersion());
        existing.setMinimumVersion(appVersion.getMinimumVersion());
        existing.setUpdateUrl(appVersion.getUpdateUrl());
        existing.setIsMandatory(appVersion.getIsMandatory());
        existing.setReleaseNotes(appVersion.getReleaseNotes());

        AppVersion saved = appVersionRepository.save(existing);
        return ResponseEntity.ok(saved);
    }
}
