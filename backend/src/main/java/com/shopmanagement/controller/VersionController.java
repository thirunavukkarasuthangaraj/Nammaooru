package com.shopmanagement.controller;

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
    public ResponseEntity<Map<String, Object>> getVersion() {
        Map<String, Object> response = new HashMap<>();
        response.put("version", appVersion);
        response.put("name", appName);
        response.put("buildTimestamp", System.currentTimeMillis());
        response.put("buildDate", new java.util.Date().toString());
        return ResponseEntity.ok(response);
    }
}