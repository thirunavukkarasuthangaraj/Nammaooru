package com.shopmanagement.controller;

import com.shopmanagement.service.SettingService;
import com.shopmanagement.shop.util.GeoLocationUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/service-area")
@RequiredArgsConstructor
public class ServiceAreaController {

    private final SettingService settingService;
    private final GeoLocationUtils geoLocationUtils;

    @GetMapping("/check")
    public ResponseEntity<Map<String, Object>> checkServiceArea(
            @RequestParam double lat,
            @RequestParam double lng) {

        Map<String, Object> response = new HashMap<>();

        try {
            String enabledStr = settingService.getSettingValue("service.area.enabled", "false");
            boolean enabled = "true".equalsIgnoreCase(enabledStr);

            if (!enabled) {
                response.put("allowed", true);
                response.put("enabled", false);
                response.put("message", "Service area restriction is disabled");
                return ResponseEntity.ok(response);
            }

            String centerLatStr = settingService.getSettingValue("service.area.center.latitude", "12.4955");
            String centerLngStr = settingService.getSettingValue("service.area.center.longitude", "78.5514");
            String radiusStr = settingService.getSettingValue("service.area.radius.km", "50");

            BigDecimal centerLat = new BigDecimal(centerLatStr);
            BigDecimal centerLng = new BigDecimal(centerLngStr);
            double radiusKm = Double.parseDouble(radiusStr);

            boolean withinRadius = geoLocationUtils.isWithinRadius(
                    BigDecimal.valueOf(lat), BigDecimal.valueOf(lng),
                    centerLat, centerLng, radiusKm);

            response.put("allowed", withinRadius);
            response.put("enabled", true);
            response.put("radiusKm", radiusKm);
            response.put("centerLat", centerLat.doubleValue());
            response.put("centerLng", centerLng.doubleValue());

            if (!withinRadius) {
                response.put("message", "Service is not available in your area. We currently operate within " + (int) radiusKm + " km of our service center.");
            } else {
                response.put("message", "You are within the service area");
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error checking service area: {}", e.getMessage());
            // Fail-open: if anything goes wrong, allow access
            response.put("allowed", true);
            response.put("enabled", false);
            response.put("message", "Service area check unavailable");
            return ResponseEntity.ok(response);
        }
    }
}
