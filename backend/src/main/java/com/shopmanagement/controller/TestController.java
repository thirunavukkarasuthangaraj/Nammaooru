package com.shopmanagement.controller;

import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/test")
@RequiredArgsConstructor
public class TestController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/reset-admin-password")
    public String resetAdminPassword() {
        User admin = userRepository.findByUsername("admin")
                .orElse(null);
        
        if (admin != null) {
            admin.setPassword(passwordEncoder.encode("admin123"));
            userRepository.save(admin);
            return "Admin password reset to 'admin123' successfully";
        }
        
        return "Admin user not found";
    }
    
    @GetMapping("/check-admin")
    public String checkAdmin() {
        User admin = userRepository.findByUsername("admin")
                .orElse(null);
        
        if (admin != null) {
            return "Admin exists - Username: " + admin.getUsername() + 
                   ", Email: " + admin.getEmail() + 
                   ", Role: " + admin.getRole() +
                   ", Enabled: " + admin.isEnabled();
        }
        
        return "Admin user not found";
    }
}