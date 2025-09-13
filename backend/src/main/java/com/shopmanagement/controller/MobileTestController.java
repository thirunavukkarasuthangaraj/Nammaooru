package com.shopmanagement.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/mobile/delivery-partner")
public class MobileTestController {
    
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        String phoneNumber = request.get("phoneNumber");
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP sent to " + phoneNumber);
        response.put("otpSent", true);
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, Object>> verifyOtp(@RequestBody Map<String, String> request) {
        String phoneNumber = request.get("phoneNumber");
        String otp = request.get("otp");
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Login successful");
        response.put("token", "sample-jwt-token");
        response.put("partnerId", "DP001");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/profile/{partnerId}")
    public ResponseEntity<Map<String, Object>> getProfile(@PathVariable String partnerId) {
        Map<String, Object> profile = new HashMap<>();
        profile.put("partnerId", partnerId);
        profile.put("name", "Test Delivery Partner");
        profile.put("phoneNumber", "9876543210");
        profile.put("isOnline", true);
        profile.put("isAvailable", true);
        
        return ResponseEntity.ok(profile);
    }
    
    @GetMapping("/orders/{partnerId}/available")
    public ResponseEntity<Map<String, Object>> getAvailableOrders(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();
        response.put("orders", new java.util.ArrayList<>());
        response.put("totalCount", 0);
        response.put("message", "No available orders at the moment");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/leaderboard")
    public ResponseEntity<Map<String, Object>> getLeaderboard() {
        Map<String, Object> response = new HashMap<>();
        response.put("leaderboard", new java.util.ArrayList<>());
        response.put("message", "Leaderboard functionality implemented");
        
        return ResponseEntity.ok(response);
    }
}