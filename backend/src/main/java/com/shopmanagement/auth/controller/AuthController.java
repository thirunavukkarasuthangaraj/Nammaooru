package com.shopmanagement.auth.controller;

import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.dto.auth.ChangePasswordRequest;
import com.shopmanagement.service.AuthService;
import com.shopmanagement.service.TokenBlacklistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenBlacklistService tokenBlacklistService;
    private final PasswordEncoder passwordEncoder;

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
    
    @PostMapping("/change-password")
    public ResponseEntity<Map<String, String>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication) {
        Map<String, String> response = new HashMap<>();
        
        if (authentication == null || !authentication.isAuthenticated()) {
            response.put("status", "error");
            response.put("message", "User not authenticated");
            return ResponseEntity.badRequest().body(response);
        }
        
        try {
            authService.changePassword(request, authentication.getName());
            response.put("status", "success");
            response.put("message", "Password changed successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/password-status")
    public ResponseEntity<Map<String, Object>> getPasswordStatus(Authentication authentication) {
        Map<String, Object> response = new HashMap<>();
        
        if (authentication != null && authentication.isAuthenticated()) {
            response = authService.getPasswordStatus(authentication.getName());
        } else {
            response.put("status", "error");
            response.put("message", "User not authenticated");
        }
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/generate-password-hash")
    public ResponseEntity<Map<String, String>> generatePasswordHash(@RequestBody Map<String, String> request) {
        Map<String, String> response = new HashMap<>();
        
        try {
            String rawPassword = request.get("password");
            if (rawPassword == null || rawPassword.trim().isEmpty()) {
                response.put("status", "error");
                response.put("message", "Password is required");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Validate password strength
            if (rawPassword.length() < 8) {
                response.put("status", "error");
                response.put("message", "Password must be at least 8 characters long");
                return ResponseEntity.badRequest().body(response);
            }
            
            String hashedPassword = passwordEncoder.encode(rawPassword);
            
            response.put("status", "success");
            response.put("rawPassword", rawPassword);
            response.put("hashedPassword", hashedPassword);
            response.put("sqlCommand", "UPDATE users SET password = '" + hashedPassword + "' WHERE username = 'your_username';");
            response.put("message", "Password hash generated successfully. Use this hash in your database.");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "error");
            response.put("message", "Error generating password hash: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}