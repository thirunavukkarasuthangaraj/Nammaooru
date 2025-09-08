package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/version")
public class VersionController {

    @Value("${app.version:@project.version@}")
    private String appVersion;

    @Value("${app.name:@project.name@}")
    private String appName;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getVersion() {
        Map<String, Object> versionData = new HashMap<>();
        versionData.put("version", appVersion);
        versionData.put("name", appName);
        versionData.put("buildTimestamp", System.currentTimeMillis());
        versionData.put("buildDate", new java.util.Date().toString());
        
        return ResponseUtil.success(versionData, "Version information retrieved successfully");
    }
}