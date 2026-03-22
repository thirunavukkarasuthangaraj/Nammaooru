package com.shopmanagement.userservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class VersionController {

    @GetMapping("/api/version")
    public ResponseEntity<Map<String, String>> getVersion() {
        return ResponseEntity.ok(Map.of(
            "service", "user-service",
            "mode", "microservice",
            "port", "8081",
            "database", "user_db",
            "message", "This response is from USER-SERVICE (microservice)"
        ));
    }
}
