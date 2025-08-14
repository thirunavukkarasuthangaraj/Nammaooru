package com.shopmanagement.controller;

import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.service.AuthService;
import com.shopmanagement.service.TokenBlacklistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenBlacklistService tokenBlacklistService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> authenticate(@Valid @RequestBody AuthRequest request) {
        return ResponseEntity.ok(authService.authenticate(request));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        Map<String, String> response = new HashMap<>();
        
        // Extract and blacklist token
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            tokenBlacklistService.blacklistToken(token);
            response.put("message", "Logged out successfully and token invalidated");
        } else {
            response.put("message", "Logged out successfully");
        }
        
        response.put("status", "success");
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateToken(Authentication authentication) {
        Map<String, Object> response = new HashMap<>();
        
        if (authentication != null && authentication.isAuthenticated()) {
            response.put("valid", true);
            response.put("username", authentication.getName());
            response.put("authorities", authentication.getAuthorities());
        } else {
            response.put("valid", false);
        }
        
        return ResponseEntity.ok(response);
    }
}